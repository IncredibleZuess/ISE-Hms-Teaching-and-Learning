// Scheduled job: assigns peers to students after the submission deadline.
// Executed server-side via node-cron polling for assignments whose peer review
// is enabled, submission deadline has passed, and no assignments exist yet.
import cron from 'node-cron';
import pool from '../db.js';
import { peerReviewLogger } from '../middleware/logger.js';

// Fisher-Yates shuffle helper
const shuffle = (array) => {
  const arr = [...array];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
};

// Assign peers for a single assignment.
// For each submitted student, randomly select N distinct peers (no self-assignment).
export const assignPeersForAssignment = async (assignmentID, numPeers) => {
  const [submissions] = await pool.execute(
    'SELECT submissionID, userID FROM submission WHERE assignmentID = ?',
    [assignmentID]
  );

  // Students who did not submit are excluded
  const submittedUsers = submissions.filter((s) => s.userID != null);

  if (submittedUsers.length < 2) {
    peerReviewLogger.info(
      `Peer assignment skipped for assignmentID: ${assignmentID}; only ${submittedUsers.length} submitted student(s)`
    );
    return { assigned: 0, message: 'Not enough submissions for peer review' };
  }

  const n = Math.min(numPeers, submittedUsers.length - 1);
  const insertValues = [];
  const params = [];

  for (const sub of submittedUsers) {
    // Candidate pool: submissions belonging to OTHER users (excluding self)
    const candidates = submittedUsers.filter((s) => s.userID !== sub.userID);
    const shuffled = shuffle(candidates);
    const selected = shuffled.slice(0, n);

    for (const peer of selected) {
      insertValues.push('(?, ?, ?)');
      params.push(assignmentID, sub.userID, peer.submissionID);
    }
  }

  if (insertValues.length === 0) {
    return { assigned: 0, message: 'No peer assignments could be created' };
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const sql = `INSERT INTO peer_review_assignments (assignment_id, reviewer_user_id, reviewee_submission_id)
                 VALUES ${insertValues.join(', ')}
                 ON DUPLICATE KEY UPDATE id = id`;
    const [result] = await conn.execute(sql, params);
    await conn.commit();
    peerReviewLogger.info(
      `Peer assignment completed for assignmentID: ${assignmentID}; ${result.affectedRows} assignments created`
    );
    return { assigned: result.affectedRows, message: 'Peer assignments created' };
  } catch (error) {
    await conn.rollback();
    peerReviewLogger.error(`Peer assignment failed for assignmentID: ${assignmentID}: ${error.message}`, { error });
    throw error;
  } finally {
    conn.release();
  }
};

// Find all assignments that are ready for peer assignment
export const findAssignmentsReadyForPeerAssignment = async () => {
  const [rows] = await pool.execute(
    `SELECT prc.assignment_id, prc.num_peers
     FROM peer_review_configs prc
     JOIN assignment a ON a.assignmentID = prc.assignment_id
     WHERE prc.enabled = TRUE
       AND a.assignDueDate < NOW()
       AND NOT EXISTS (
         SELECT 1 FROM peer_review_assignments pra
         WHERE pra.assignment_id = prc.assignment_id
       )`
  );
  return rows;
};

// Main scheduled task - polls every 10 minutes
export const runPeerAssignmentJob = async () => {
  try {
    const assignments = await findAssignmentsReadyForPeerAssignment();
    if (assignments.length === 0) return;

    peerReviewLogger.info(`Running peer assignment job for ${assignments.length} assignment(s)`);
    for (const { assignment_id, num_peers } of assignments) {
      try {
        await assignPeersForAssignment(assignment_id, num_peers);
      } catch (e) {
        peerReviewLogger.error(`Error in peer assignment for assignment ${assignment_id}: ${e.message}`);
      }
    }
  } catch (error) {
    peerReviewLogger.error(`Peer assignment job error: ${error.message}`, { error });
  }
};

// Schedule the job (every 10 minutes). Use "*/10 * * * *" for cron.
export const startPeerAssignmentCron = () => {
  const schedule = process.env.PEER_ASSIGNMENT_CRON || '*/10 * * * *';
  const task = cron.schedule(schedule, runPeerAssignmentJob);
  peerReviewLogger.info(`Peer assignment cron scheduled: ${schedule}`);
  return task;
};