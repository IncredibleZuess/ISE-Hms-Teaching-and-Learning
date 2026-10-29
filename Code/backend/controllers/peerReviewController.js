import pool from '../db.js';
import { peerReviewLogger } from '../middleware/logger.js';
import minioClient from '../minioClient.js';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const MINIO_BUCKET = process.env.MINIO_BUCKET || 'student-videos';
const MINIO_PREFIX = 'HMS-Video-Uploads';

// Generate a fresh signed URL for a submission video
async function getVideoSignedUrl(videoId) {
  const objectKey = `${MINIO_PREFIX}/${videoId}`;
  const command = new GetObjectCommand({ Bucket: MINIO_BUCKET, Key: objectKey });
  return getSignedUrl(minioClient, command, { expiresIn: 86400 });
}

// Validate rubric criteria: array of {name, description, weight} summing to 100
const validateRubricCriteria = (criteria) => {
  if (!Array.isArray(criteria) || criteria.length === 0) {
    return { valid: false, message: 'Rubric criteria must be a non-empty array' };
  }
  let total = 0;
  for (const c of criteria) {
    if (!c.name || typeof c.name !== 'string' || c.name.trim() === '') {
      return { valid: false, message: 'Each rubric criterion requires a name', criteria: c };
    }
    if (typeof c.weight !== 'number' || isNaN(c.weight) || c.weight < 0 || c.weight > 100) {
      return { valid: false, message: `Criterion weight must be a number between 0 and 100: "${c.name}"` };
    }
    total += c.weight;
  }
  if (Math.abs(total - 100) > 0.001) {
    return { valid: false, message: `Rubric weights must total 100% (current total: ${total}%)` };
  }
  return { valid: true };
};

// POST /v1/assignments/:assignmentID/peer-review/config
// Create or update the peer review configuration for an assignment (Lecturer/Admin)
export const configurePeerReview = async (req, res) => {
  const { assignmentID } = req.params;
  const { enabled, numPeers, deadline, rubric } = req.body;

  try {
    // Verify the assignment exists and fetch its due date
    const [assignmentRows] = await pool.execute(
      'SELECT assignmentID, assignDueDate, userID FROM assignment WHERE assignmentID = ?',
      [assignmentID]
    );
    if (assignmentRows.length === 0) {
      return res.status(404).json({ message: 'Assignment not found' });
    }
    const assignment = assignmentRows[0];

    // Validate numPeers (1-5)
    let peers = numPeers;
    if (peers != null) {
      peers = Number(peers);
      if (!Number.isInteger(peers) || peers < 1 || peers > 5) {
        return res.status(400).json({ message: 'Number of peers must be an integer between 1 and 5' });
      }
    } else {
      peers = 2; // default
    }

    // Validate deadline (must be after assignment due date)
    let prDeadline = deadline;
    if (prDeadline) {
      const prDate = new Date(prDeadline);
      if (isNaN(prDate.getTime())) {
        return res.status(400).json({ message: 'Invalid peer review deadline' });
      }
      if (prDate <= new Date(assignment.assignDueDate)) {
        return res.status(400).json({ message: 'Peer review deadline must be after the assignment due date' });
      }
      prDeadline = prDate.toISOString().slice(0, 19).replace('T', ' ');
    }

    // Handle rubric (optional: create new rubric in same request)
    let rubricId = null;
    if (rubric && rubric.name && rubric.criteria) {
      const validation = validateRubricCriteria(rubric.criteria);
      if (!validation.valid) {
        return res.status(400).json({ message: validation.message });
      }
      const [rubricResult] = await pool.execute(
        'INSERT INTO peer_review_rubrics (name, criteria, created_by) VALUES (?, ?, ?)',
        [rubric.name.trim(), JSON.stringify(rubric.criteria), req.user.userID]
      );
      rubricId = rubricResult.insertId;
    } else if (rubric && rubric.rubricId) {
      // Reference an existing rubric
      const [existing] = await pool.execute(
        'SELECT rubric_id FROM peer_review_rubrics WHERE rubric_id = ?',
        [rubric.rubricId]
      );
      if (existing.length === 0) {
        return res.status(404).json({ message: 'Rubric not found' });
      }
      rubricId = rubric.rubricId;
    }

    // Upsert the config
    const existingConfig = await pool.execute(
      'SELECT config_id FROM peer_review_configs WHERE assignment_id = ?',
      [assignmentID]
    );
    const [cfgRows] = existingConfig;

    if (cfgRows.length > 0) {
      await pool.execute(
        `UPDATE peer_review_configs
         SET enabled = ?, num_peers = ?, deadline = ?, rubric_id = ?
         WHERE assignment_id = ?`,
        [enabled ? 1 : 0, peers, prDeadline, rubricId, assignmentID]
      );
    } else {
      await pool.execute(
        `INSERT INTO peer_review_configs (assignment_id, enabled, num_peers, deadline, rubric_id)
         VALUES (?, ?, ?, ?, ?)`,
        [assignmentID, enabled ? 1 : 0, peers, prDeadline, rubricId]
      );
    }

    peerReviewLogger.info(`Peer review config saved for assignmentID: ${assignmentID}`);
    res.json({
      message: 'Peer review configuration saved',
      config: { enabled: !!enabled, numPeers: peers, deadline: prDeadline, rubricId },
    });
  } catch (error) {
    peerReviewLogger.error(`Error saving peer review config: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to save peer review configuration' });
  }
};

// GET /v1/assignments/:assignmentID/peer-review/config
// Return the active peer review config + rubric for an assignment (Student/Lecturer/Admin)
export const getPeerReviewConfig = async (req, res) => {
  const { assignmentID } = req.params;

  try {
    const [cfgRows] = await pool.execute(
      `SELECT prc.enabled, prc.num_peers, prc.deadline, prc.rubric_id,
              prr.name AS rubricName, prr.criteria AS rubricCriteria
       FROM peer_review_configs prc
       LEFT JOIN peer_review_rubrics prr ON prr.rubric_id = prc.rubric_id
       WHERE prc.assignment_id = ?`,
      [assignmentID]
    );

    if (cfgRows.length === 0) {
      return res.json({ enabled: false, config: null, rubric: null });
    }

    const cfg = cfgRows[0];
    let criteria = [];
    try {
      criteria = JSON.parse(cfg.rubricCriteria || '[]');
    } catch (e) {
      peerReviewLogger.warn(`Could not parse rubric criteria for assignmentID: ${assignmentID}`);
    }

    peerReviewLogger.info(`Fetched peer review config for assignmentID: ${assignmentID}`);
    res.json({
      enabled: !!cfg.enabled,
      config: {
        enabled: !!cfg.enabled,
        numPeers: cfg.num_peers,
        deadline: cfg.deadline,
        rubricId: cfg.rubric_id,
      },
      rubric: {
        name: cfg.rubricName || null,
        criteria,
      },
    });
  } catch (error) {
    peerReviewLogger.error(`Error fetching peer review config: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to fetch peer review configuration' });
  }
};

// GET /v1/assignments/:assignmentID/peer-review/my-reviews
// Student: fetch the list of assigned peer submissions to review
export const getAssignedReviews = async (req, res) => {
  const { assignmentID } = req.params;
  const { userID } = req.user;

  try {
    const [rows] = await pool.execute(
      `SELECT pra.id AS assignmentEntryId,
              pra.reviewee_submission_id AS submissionID,
              s.submissionVidName,
              s.uploadedAt,
              prs.id AS reviewSubmissionId,
              prs.submitted_at
       FROM peer_review_assignments pra
       JOIN submission s ON s.submissionID = pra.reviewee_submission_id
       LEFT JOIN peer_review_submissions prs
              ON prs.assignment_id = pra.assignment_id
             AND prs.reviewer_id = pra.reviewer_user_id
             AND prs.reviewee_submission_id = pra.reviewee_submission_id
       WHERE pra.assignment_id = ? AND pra.reviewer_user_id = ?`,
      [assignmentID, userID]
    );

    const reviews = await Promise.all(rows.map(async (row) => {
      let videoUrl = null;
      try {
        videoUrl = await getVideoSignedUrl(row.submissionVidName);
      } catch (err) {
        peerReviewLogger.warn(`Could not generate signed URL for peer video ${row.submissionVidName}: ${err.message}`);
      }
      return {
        assignmentId: Number(assignmentID),
        revieweeSubmissionId: row.submissionID,
        videoUrl,
        uploadedAt: row.uploadedAt,
        completed: row.reviewSubmissionId != null,
        reviewedAt: row.submitted_at || null,
      };
    }));

    peerReviewLogger.info(`Fetched ${reviews.length} assigned reviews for userID: ${userID}, assignmentID: ${assignmentID}`);
    res.json({ reviews });
  } catch (error) {
    peerReviewLogger.error(`Error fetching assigned reviews: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to fetch assigned reviews' });
  }
};

// POST /v1/peer-reviews/:assignmentID
// Student: submit a completed peer review
export const submitPeerReview = async (req, res) => {
  const { assignmentID } = req.params;
  const { userID } = req.user; // reviewer
  const { revieweeSubmissionId, rubricScores, comments } = req.body;

  try {
    if (!revieweeSubmissionId) {
      return res.status(400).json({ message: 'revieweeSubmissionId is required' });
    }

    // Verify there is an existing assignment for this reviewer+reviewee
    const [assignRows] = await pool.execute(
      `SELECT pra.id, pra.reviewee_submission_id
       FROM peer_review_assignments pra
       WHERE pra.assignment_id = ? AND pra.reviewer_user_id = ? AND pra.reviewee_submission_id = ?`,
      [assignmentID, userID, revieweeSubmissionId]
    );
    if (assignRows.length === 0) {
      return res.status(403).json({ message: 'You are not assigned to review this submission' });
    }

    // Enforce no self-review
    const [subOwner] = await pool.execute(
      'SELECT userID FROM submission WHERE submissionID = ?',
      [revieweeSubmissionId]
    );
    if (subOwner.length === 0) {
      return res.status(404).json({ message: 'Reviewee submission not found' });
    }
    if (subOwner[0].userID === userID) {
      return res.status(403).json({ message: 'You cannot review your own submission' });
    }

    // Check deadline
    const [cfgRows] = await pool.execute(
      'SELECT deadline, enabled FROM peer_review_configs WHERE assignment_id = ?',
      [assignmentID]
    );
    if (cfgRows.length === 0 || !cfgRows[0].enabled) {
      return res.status(400).json({ message: 'Peer review is not enabled for this assignment' });
    }
    if (cfgRows[0].deadline && new Date() > new Date(cfgRows[0].deadline)) {
      return res.status(400).json({ message: 'Peer review deadline has passed' });
    }

    // Check existing submission (locks after completion)
    const [existing] = await pool.execute(
      `SELECT id FROM peer_review_submissions
       WHERE assignment_id = ? AND reviewer_id = ? AND reviewee_submission_id = ?`,
      [assignmentID, userID, revieweeSubmissionId]
    );
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Peer review already submitted; it is locked' });
    }

    // Validate rubric scores against config rubric
    const [cfgFull] = await pool.execute(
      `SELECT prc.rubric_id, prr.criteria
       FROM peer_review_configs prc
       LEFT JOIN peer_review_rubrics prr ON prr.rubric_id = prc.rubric_id
       WHERE prc.assignment_id = ?`,
      [assignmentID]
    );
    const rubric = cfgFull[0]?.rubric_id ? JSON.parse(cfgFull[0].criteria || '[]') : [];
    if (rubric.length > 0) {
      if (!Array.isArray(rubricScores) || rubricScores.length !== rubric.length) {
        return res.status(400).json({ message: `Rubric scores must cover all ${rubric.length} criteria` });
      }
      for (let i = 0; i < rubric.length; i++) {
        const maxWeight = rubric[i].weight;
        const score = rubricScores[i]?.score;
        if (score == null || isNaN(score) || score < 0 || score > maxWeight) {
          return res.status(400).json({
            message: `Score for criterion "${rubric[i].name}" must be between 0 and ${maxWeight}`,
          });
        }
      }
    }

    await pool.execute(
      `INSERT INTO peer_review_submissions
         (assignment_id, reviewer_id, reviewee_id, reviewee_submission_id, rubric_scores, comments)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [assignmentID, userID, subOwner[0].userID, revieweeSubmissionId,
       JSON.stringify(rubricScores || []), comments || null]
    );

    peerReviewLogger.info(`Peer review submitted by userID: ${userID} for submissionID: ${revieweeSubmissionId}`);
    res.status(201).json({ message: 'Peer review submitted successfully' });
  } catch (error) {
    peerReviewLogger.error(`Error submitting peer review: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to submit peer review' });
  }
};

// GET /v1/assignments/:assignmentID/peer-review/results
// Student: view own peer review results (aggregated scores + individual comments) after deadline
export const getPeerReviewResults = async (req, res) => {
  const { assignmentID } = req.params;
  const { userID } = req.user;

  try {
    // Check config and deadline
    const [cfgRows] = await pool.execute(
      'SELECT deadline, enabled FROM peer_review_configs WHERE assignment_id = ?',
      [assignmentID]
    );
    if (cfgRows.length === 0 || !cfgRows[0].enabled) {
      return res.status(400).json({ message: 'Peer review is not enabled for this assignment' });
    }
    if (cfgRows[0].deadline && new Date() < new Date(cfgRows[0].deadline)) {
      return res.status(403).json({ message: 'Peer review results are only visible after the peer review deadline' });
    }

    // Fetch all reviews where reviewee_id = current user
    const [reviews] = await pool.execute(
      `SELECT prs.id, prs.rubric_scores, prs.comments, prs.submitted_at,
              u.firstName, u.lastName
       FROM peer_review_submissions prs
       JOIN users u ON u.userID = prs.reviewer_id
       WHERE prs.assignment_id = ? AND prs.reviewee_id = ?`,
      [assignmentID, userID]
    );

    const parsed = reviews.map((r) => {
      let scores = [];
      try { scores = JSON.parse(r.rubric_scores || '[]'); } catch (e) { /* ignore */ }
      const total = scores.reduce((sum, s) => sum + (Number(s.score) || 0), 0);
      return {
        reviewId: r.id,
        rubricScores: scores,
        totalScore: total,
        comments: r.comments,
        submittedAt: r.submitted_at,
        reviewerName: `${r.firstName} ${r.lastName}`,
      };
    });

    // Aggregate total, and overall average
    const aggregateScore = parsed.length
      ? parsed.reduce((sum, p) => sum + p.totalScore, 0) / parsed.length
      : 0;

    res.json({
      assignmentId: Number(assignmentID),
      reviewCount: parsed.length,
      aggregateScore: Number(aggregateScore.toFixed(2)),
      reviews: parsed,
    });
  } catch (error) {
    peerReviewLogger.error(`Error fetching peer review results: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to fetch peer review results' });
  }
};

// GET /v1/assignments/:assignmentID/peer-review/all
// Lecturer/Admin: view all peer review submissions for an assignment
export const getAllPeerReviews = async (req, res) => {
  const { assignmentID } = req.params;

  try {
    const [reviews] = await pool.execute(
      `SELECT prs.id AS reviewId,
              reviewer.firstName AS reviewerFirstName,
              reviewer.lastName AS reviewerLastName,
              reviewer.username AS reviewerNumber,
              reviewee.firstName AS revieweeFirstName,
              reviewee.lastName AS revieweeLastName,
              reviewee.username AS revieweeNumber,
              prs.rubric_scores,
              prs.comments,
              prs.submitted_at,
              prr.name AS rubricName,
              prr.criteria AS rubricCriteria
       FROM peer_review_submissions prs
       JOIN users reviewer ON reviewer.userID = prs.reviewer_id
       JOIN users reviewee ON reviewee.userID = prs.reviewee_id
       LEFT JOIN peer_review_configs prc ON prc.assignment_id = prs.assignment_id
       LEFT JOIN peer_review_rubrics prr ON prr.rubric_id = prc.rubric_id
       WHERE prs.assignment_id = ?
       ORDER BY prs.submitted_at DESC`,
      [assignmentID]
    );

    const parsed = reviews.map((r) => {
      let scores = [];
      let criteria = [];
      try { scores = JSON.parse(r.rubric_scores || '[]'); } catch (e) { /* ignore */ }
      try { criteria = JSON.parse(r.rubricCriteria || '[]'); } catch (e) { /* ignore */ }
      const total = scores.reduce((sum, s) => sum + (Number(s.score) || 0), 0);
      return {
        reviewId: r.reviewId,
        reviewer: `${r.reviewerFirstName} ${r.reviewerLastName} (${r.reviewerNumber})`,
        reviewee: `${r.revieweeFirstName} ${r.revieweeLastName} (${r.revieweeNumber})`,
        rubricName: r.rubricName,
        rubricCriteria: criteria,
        rubricScores: scores,
        totalScore: total,
        comments: r.comments,
        submittedAt: r.submitted_at,
      };
    });

    res.json({ assignmentId: Number(assignmentID), reviews: parsed });
  } catch (error) {
    peerReviewLogger.error(`Error fetching all peer reviews: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to fetch peer reviews' });
  }
};

// PATCH /v1/peer-reviews/:reviewID/override
// Lecturer/Admin: override a peer review score
export const overridePeerReviewScore = async (req, res) => {
  const { reviewID } = req.params;
  const { overrideScore, overrideComment } = req.body;

  try {
    const [existing] = await pool.execute(
      'SELECT id FROM peer_review_submissions WHERE id = ?',
      [reviewID]
    );
    if (existing.length === 0) {
      return res.status(404).json({ message: 'Peer review not found' });
    }

    // Store override as JSON that includes original + override so original is retained for record
    const [current] = await pool.execute(
      'SELECT rubric_scores, comments FROM peer_review_submissions WHERE id = ?',
      [reviewID]
    );

    // ALTER-style: drop and re-add override column handled by migration note; store in a new column
    await pool.execute(
      `UPDATE peer_review_submissions
       SET override_score = ?, override_comment = ?
       WHERE id = ?`,
      [overrideScore != null ? overrideScore : null, overrideComment || null, reviewID]
    );

    peerReviewLogger.info(`Peer review override saved for reviewID: ${reviewID}`);
    res.json({
      message: 'Peer review score overridden',
      original: JSON.parse(current[0].rubric_scores || '[]'),
      overrideScore,
    });
  } catch (error) {
    peerReviewLogger.error(`Error overriding peer review: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to override peer review' });
  }
};