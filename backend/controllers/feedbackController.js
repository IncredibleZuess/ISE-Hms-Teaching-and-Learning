import pool from '../db.js';  // Database connection
import XLSX from 'xlsx';
import  {parse}  from 'json2csv';
import { feedbackLogger } from '../middleware/logger.js';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import 'dotenv/config';
import minioClient from '../minioClient.js';
import { PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const MINIO_BUCKET = process.env.MINIO_BUCKET_VOICE_NOTES || 'voice-notes';
const VOICE_NOTE_PREFIX = 'voicenotes';

const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE);

// Configure multer for voice note uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/voicenotes';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'voicenote-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const uploadVoiceNote = multer({
  storage: storage,
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (req, file, cb) => {
    // Accept audio files
    const allowedMimeTypes = [
      'audio/mpeg',
      'audio/mp3',
      'audio/mp4',
      'audio/m4a',
      'audio/x-m4a',
      'audio/wav',
      'audio/wave',
      'audio/x-wav',
      'audio/webm',
      'audio/ogg',
      'audio/vnd.wav',
      'audio/aac'
    ];

    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Only audio files are allowed.`));
    }
  }
}).single('voiceNote');

// Helper function to upload file to MinIO
async function uploadToMinIO(filePath, fileName) {
  try {
    const fileData = fs.readFileSync(filePath);
    const objectKey = `${VOICE_NOTE_PREFIX}/${fileName}`;

    await minioClient.send(
      new PutObjectCommand({
        Bucket: MINIO_BUCKET,
        Key: objectKey,
        Body: fileData,
      })
    );

    feedbackLogger.info(`Uploaded voice note to MinIO: ${objectKey}`);
    return objectKey;
  } catch (error) {
    feedbackLogger.error(`Error uploading to MinIO: ${error.message}`, { error });
    throw error;
  }
}

// Helper function to get signed URL from MinIO
async function getVoiceNoteUrl(fileName) {
  try {
    const objectKey = `${VOICE_NOTE_PREFIX}/${fileName}`;
    const command = new GetObjectCommand({
      Bucket: MINIO_BUCKET,
      Key: objectKey,
    });

    const downloadUrl = await getSignedUrl(minioClient, command, { expiresIn: 3600 }); // 1 hour
    return downloadUrl;
  } catch (error) {
    feedbackLogger.error(`Error generating voice note URL: ${error.message}`, { error });
    throw error;
  }
}

// Helper function to delete file from MinIO
async function deleteFromMinIO(fileName) {
  try {
    const objectKey = `${VOICE_NOTE_PREFIX}/${fileName}`;

    await minioClient.send(
      new DeleteObjectCommand({
        Bucket: MINIO_BUCKET,
        Key: objectKey,
      })
    );

    feedbackLogger.info(`Deleted voice note from MinIO: ${objectKey}`);
  } catch (error) {
    feedbackLogger.error(`Error deleting from MinIO: ${error.message}`, { error });
    throw error;
  }
}



// Get feedback for a specific submission
export const getFeedback = async (req, res) => {
  const { submissionID } = req.params; // Get submissionID from URL parameters
  const { userID, userType } = req.user; // Get user info from token

  if (!submissionID) {
    feedbackLogger.warn("Missing submissionID for fetching feedback");
    return res.status(400).json({ message: "Submission ID is required" });
  }

  // Admin/Lecturer may see any submission; a Student may only see their own.
  const isStaff = userType === "Admin" || userType === "Lecturer" ? 1 : 0;

  try {
    // If user is a student, verify they own the submission
    if (userType === 'Student') {
      const [submissionCheck] = await pool.execute(
        'SELECT userID FROM submission WHERE submissionID = ?',
        [submissionID]
      );

      if (submissionCheck.length === 0) {
        feedbackLogger.warn('Submission not found when student tried to fetch feedback', { submissionID, userID });
        return res.status(404).json({ message: 'Submission not found' });
      }

      if (submissionCheck[0].userID !== userID) {
        feedbackLogger.warn('Student attempted to access feedback for another student\'s submission', { submissionID, userID });
        return res.status(403).json({ message: 'You are not authorized to view this feedback' });
      }
    }

    // Fetch feedback based on the submissionID
    const [feedback] = await pool.execute(
      `SELECT feedbackID, comment, mark, voiceNotePath, voiceNoteFileName, voiceNoteDuration
       FROM feedback
       WHERE submissionID = ?`,
      [submissionID]
    );

    if (feedback.length === 0) {
      feedbackLogger.info(
        `No feedback found or not authorised for submissionID: ${submissionID}`,
        { submissionID, userID, userType }
      );
      return res
        .status(200)
        .json({ feedbackExists: "f", message: "No feedback found" });
    }

    // Log success for retrieving feedback
    feedbackLogger.info(`Feedback retrieved successfully for submissionID: ${submissionID}`, { userType, userID });

    // Generate proxy URL for voice note if it exists
    let voiceNoteUrl = null;
    if (feedback[0].voiceNoteFileName) {
      voiceNoteUrl = `${process.env.BASE_URL || 'http://localhost:3000'}/v1/feedback/${feedback[0].feedbackID}/voice-note/stream`;
    }

    // Respond with the feedback (comment, mark, voice note) and flag that feedback exists
    res.json({
      feedbackExists: 't', // 't' indicates that feedback exists
      feedbackID: feedback[0].feedbackID,
      comment: feedback[0].comment,
      mark: feedback[0].mark,
      voiceNotePath: voiceNoteUrl,
      voiceNoteFileName: feedback[0].voiceNoteFileName,
      voiceNoteDuration: feedback[0].voiceNoteDuration
    });
  } catch (error) {
    feedbackLogger.error(
      `Error fetching feedback for submissionID ${submissionID}: ${error.message}`,
      { error }
    );
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Student marks their own feedback as viewed
// Student marks their feedback as viewed
export const markFeedbackViewed = async (req, res) => {
  const { feedbackID } = req.params;
  const { userID } = req.user;

  if (!feedbackID) {
    return res.status(400).json({ message: 'feedbackID is required' });
  }

  try {
    // Make sure this feedback belongs to a submission by the current student
    const [rows] = await pool.query(
      `SELECT f.feedbackID
       FROM feedback f
       INNER JOIN submission s ON s.submissionID = f.submissionID
       WHERE f.feedbackID = ?
         AND s.userID = ?`,
      [feedbackID, userID]
    );

    if (rows.length === 0) {
      // Either not found or not owned by this student
      return res.status(403).json({ message: 'Not authorised to mark this feedback as viewed' });
    }

    // Idempotent update: only set if NULL
    const [result] = await pool.query(
      `UPDATE feedback
       SET feedbackViewed = TRUE,
           viewedAt = COALESCE(viewedAt, NOW())
       WHERE feedbackID = ?`,
      [feedbackID]
    );

    return res.status(200).json({ message: 'Feedback marked as viewed' });
  } catch (error) {
    feedbackLogger.error(`Error marking feedback viewed: ${error.message}`, { error });
    return res.status(500).json({ message: 'Internal server error' });
  }
};





// Add feedback
export const addFeedback = async (req, res) => {
  const { submissionID, comment, mark } = req.body;
  const { userID } = req.user;

  // Ensure all required fields are provided
  if (!submissionID || !comment || mark === undefined) {
    // Log warning for missing required fields (warning log)
    feedbackLogger.warn('Missing required fields for adding feedback');
    return res.status(400).json({ message: 'Submission ID, comment, and mark are required' });
  }

  try {
    const result = await pool.execute(
      'INSERT INTO feedback (submissionID, userID, comment, mark) VALUES (?, ?, ?, ?)',
      [submissionID, userID || null, comment, mark]
    );
    // Log success for adding feedback (information log)
    feedbackLogger.info('Feedback added successfully', { feedbackID: result[0].insertId });
    res.status(201).json({ message: 'Feedback added successfully', feedbackID: result[0].insertId });
  } catch (error) {
    // Log error if adding feedback fails (error log)
    feedbackLogger.error(`Error adding feedback: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Update feedback
export const updateFeedback = async (req, res) => {
  const { feedbackID } = req.params;
  const { comment, mark } = req.body;

  // Ensure both fields are provided
  if (!comment || mark === undefined) {
    // Log warning if missing required fields (warning log)
    feedbackLogger.warn('Missing fields required for updating feedback');
    return res.status(400).json({ message: 'Comment and mark are required' });
  }

  try {
    const [result] = await pool.execute(
      'UPDATE feedback SET comment = ?, mark = ? WHERE feedbackID = ?',
      [comment, mark, feedbackID]
    );

    if (result.affectedRows === 0) {
      // Log warning for feedback not found (warning log)
      feedbackLogger.warn('Feedback not found for update', { feedbackID });
      return res.status(404).json({ message: 'Feedback not found' });
    }

    // Log success for updated feedback (information log)
    feedbackLogger.info('Feedback updated successfully', { feedbackID });
    res.status(200).json({ message: 'Feedback updated successfully' });
  } catch (error) {
    // Log error when updating feedback fails (error log)
    feedbackLogger.error(`Error updating feedback: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Delete feedback
export const deleteFeedback = async (req, res) => {
  const { feedbackID } = req.params;

  try {
    const [result] = await pool.execute(
      'DELETE FROM feedback WHERE feedbackID = ?',
      [feedbackID]
    );

    if (result.affectedRows === 0) {
      // Log warning for feedback not found (warning log)
      feedbackLogger.warn('Feedback not found for deletion:', { feedbackID });
      return res.status(404).json({ message: 'Feedback not found' });
    }

    // Log success when feedback is deleted (information log)
    feedbackLogger.info('Feedback deleted successfully', { feedbackID });
    res.status(200).json({ message: 'Feedback deleted successfully' });
  } catch (error) {
    feedbackLogger.error(`Error deleting feedback: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Mark feedback as viewed by student
export const markFeedbackAsViewed = async (req, res) => {
  const { feedbackID } = req.params;
  const { userID } = req.user;

  try {
    // First, verify that this feedback belongs to a submission by this student
    const [feedbackCheck] = await pool.execute(
      `SELECT f.feedbackID, s.userID
       FROM feedback f
       INNER JOIN submission s ON f.submissionID = s.submissionID
       WHERE f.feedbackID = ?`,
      [feedbackID]
    );

    if (feedbackCheck.length === 0) {
      feedbackLogger.warn('Feedback not found when marking as viewed', { feedbackID });
      return res.status(404).json({ message: 'Feedback not found' });
    }

    // Check if the feedback belongs to the requesting student
    if (feedbackCheck[0].userID !== userID) {
      feedbackLogger.warn('Unauthorized attempt to mark feedback as viewed', { feedbackID, userID });
      return res.status(403).json({ message: 'You are not authorized to view this feedback' });
    }

    // Update the feedback to mark it as viewed
    const [result] = await pool.execute(
      'UPDATE feedback SET feedbackViewed = TRUE, viewedAt = NOW() WHERE feedbackID = ?',
      [feedbackID]
    );

    if (result.affectedRows === 0) {
      feedbackLogger.warn('Failed to update feedback viewed status', { feedbackID });
      return res.status(500).json({ message: 'Failed to mark feedback as viewed' });
    }

    feedbackLogger.info('Feedback marked as viewed successfully', { feedbackID, userID });
    res.status(200).json({ message: 'Feedback marked as viewed successfully' });
  } catch (error) {
    feedbackLogger.error(`Error marking feedback as viewed: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};









// Get student marks based on moduleID and student userID
export const getStudentMarksByUserAndModule = async (req, res) => {
  const { moduleID} = req.params;  // Extract moduleID (for the module) and userID (for the student)
  const { userID } = req.user;  // Extract userID (for the student)

  try {
    // Query to get assignment name, student mark, comment, feedbackID, and total marks
    const [rows] = await pool.query(
      `SELECT
         a.assignName,
         f.feedbackID,
         f.mark,
         f.comment,
         a.assignTotalMarks
       FROM
         submission s
       INNER JOIN
         feedback f ON s.submissionID = f.submissionID
       INNER JOIN
         assignment a ON s.assignmentID = a.assignmentID
       WHERE
         a.moduleID = ?
         AND s.userID = ?`,
      [moduleID, userID]
    );

    // If no data is found
    if (rows.length === 0) {
      // Log warning if no marks found for module and user (warning log)
      feedbackLogger.warn('No marks found for the specified moduleID and userID', { moduleID, userID });
      return res.status(404).json({ message: 'No marks found for the specified moduleID and userID' });
    }

    // Map to the shape your app already uses; include studentName for staff (safe extra)
    const feedback = rows.map(row => {
      const hasMark = row.mark != null && row.assignTotalMarks != null;
      const percentage = hasMark
        ? ((row.mark / row.assignTotalMarks) * 100).toFixed(2)
        : null;

      return {
        assignName: row.assignName,
        feedbackID: row.feedbackID,
        markFormatted: `${row.mark}/${row.assignTotalMarks} (${percentage}%)`,  // Format mark/total and percentage
        comment: row.comment
      };
    });

    return res.status(200).json({ feedback });
  } catch (error) {
    feedbackLogger.error(`Error fetching marks: ${error.message}`, { error, moduleID, userID, userType });
    return res.status(500).json({ message: 'Error fetching marks' });
  }
};


export const getModuleMarksForStaff = async (req, res) => {
  const { moduleID } = req.params;

  try {
    // Latest feedback per submission for ALL students in the module
    const [rows] = await pool.query(
      `
      SELECT
        u.firstName      AS firstName,
        u.lastName       AS lastName,
        u.username       AS username,
        f.comment        AS comment,
        f.mark           AS mark,
        a.assignTotalMarks AS totalMarks,
        ROUND((f.mark / a.assignTotalMarks) * 100, 2) AS percentage,
        CASE WHEN f.viewedAt IS NOT NULL THEN 1 ELSE 0 END AS feedbackViewed
      FROM submission s
      INNER JOIN users u      ON u.userID = s.userID
      INNER JOIN assignment a ON a.assignmentID = s.assignmentID
      INNER JOIN (
        SELECT f1.*
        FROM feedback f1
        INNER JOIN (
          SELECT submissionID, MAX(feedbackID) AS maxId
          FROM feedback
          GROUP BY submissionID
        ) lf ON lf.maxId = f1.feedbackID
      ) f ON f.submissionID = s.submissionID
      WHERE a.moduleID = ?
      ORDER BY u.lastName, u.firstName, a.assignName
      `,
      [moduleID]
    );

    // Always return 200 (let UI show empty state)
    return res.status(200).json({ rows });
  } catch (error) {
    // Log error when fetching marks fails (error log)
    feedbackLogger.error(`Error fetching marks: ${error.message}`, { error });
    res.status(500).json({ message: 'Error fetching marks', error });
  }
};

// Get gradebook for a specific assignment (for staff)
export const getAssignmentGradebookForStaff = async (req, res) => {
  const { assignmentID } = req.params;

  try {
    // Get assignment info and all students' feedback for this assignment
    const [rows] = await pool.query(
      `
      SELECT
        a.assignName     AS assignName,
        a.assignTotalMarks AS totalMarks,
        u.firstName      AS firstName,
        u.lastName       AS lastName,
        u.username       AS username,
        f.comment        AS comment,
        f.mark           AS mark,
        ROUND((f.mark / a.assignTotalMarks) * 100, 2) AS percentage,
        CASE WHEN f.viewedAt IS NOT NULL THEN 1 ELSE 0 END AS feedbackViewed
      FROM submission s
      INNER JOIN users u      ON u.userID = s.userID
      INNER JOIN assignment a ON a.assignmentID = s.assignmentID
      INNER JOIN (
        SELECT f1.*
        FROM feedback f1
        INNER JOIN (
          SELECT submissionID, MAX(feedbackID) AS maxId
          FROM feedback
          GROUP BY submissionID
        ) lf ON lf.maxId = f1.feedbackID
      ) f ON f.submissionID = s.submissionID
      WHERE a.assignmentID = ?
      ORDER BY u.lastName, u.firstName
      `,
      [assignmentID]
    );

    // Always return 200 (let UI show empty state)
    return res.status(200).json({
      assignName: rows.length > 0 ? rows[0].assignName : null,
      rows
    });
  } catch (error) {
    feedbackLogger.error(`Error fetching assignment gradebook: ${error.message}`, { error });
    res.status(500).json({ message: 'Error fetching assignment gradebook', error });
  }
};







// Upload voice note for feedback
export const uploadVoiceNoteFeedback = async (req, res) => {
  uploadVoiceNote(req, res, async (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          feedbackLogger.warn('Voice note file size exceeds limit');
          return res.status(400).json({ message: 'File size exceeds the maximum limit' });
        }
      }
      feedbackLogger.error(`Error uploading voice note: ${err.message}`, { err });
      return res.status(400).json({ message: err.message });
    }

    const { feedbackID } = req.params;
    const { duration } = req.body; // Duration in seconds from frontend

    if (!req.file) {
      feedbackLogger.warn('No voice note file provided');
      return res.status(400).json({ message: 'Voice note file is required' });
    }

    try {
      // Check if feedback exists
      const [feedbackCheck] = await pool.execute(
        'SELECT feedbackID, voiceNoteFileName FROM feedback WHERE feedbackID = ?',
        [feedbackID]
      );

      if (feedbackCheck.length === 0) {
        feedbackLogger.warn('Feedback not found for voice note upload', { feedbackID });
        // Delete uploaded file
        fs.unlinkSync(req.file.path);
        return res.status(404).json({ message: 'Feedback not found' });
      }

      // Delete old voice note from MinIO if exists
      if (feedbackCheck[0].voiceNoteFileName) {
        try {
          await deleteFromMinIO(feedbackCheck[0].voiceNoteFileName);
        } catch (error) {
          feedbackLogger.warn(`Could not delete old voice note: ${error.message}`);
        }
      }

      // Upload to MinIO
      const uploadResult = await uploadToMinIO(req.file.path, req.file.filename);

      // Update feedback with voice note info
      await pool.execute(
        'UPDATE feedback SET voiceNotePath = ?, voiceNoteFileName = ?, voiceNoteDuration = ? WHERE feedbackID = ?',
        [`voicenotes/${req.file.filename}`, req.file.filename, duration || null, feedbackID]
      );

      // Delete local file after successful upload
      fs.unlinkSync(req.file.path);

      feedbackLogger.info('Voice note uploaded successfully', { feedbackID, fileName: req.file.filename });
      res.status(200).json({
        message: 'Voice note uploaded successfully',
        voiceNoteFileName: req.file.filename
      });
    } catch (error) {
      feedbackLogger.error(`Error uploading voice note: ${error.message}`, { error });
      // Clean up local file if exists
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      res.status(500).json({ message: 'Internal server error' });
    }
  });
};

// Get voice note for feedback (returns URL to backend proxy)
export const getVoiceNoteFeedback = async (req, res) => {
  const { feedbackID } = req.params;

  try {
    const [feedback] = await pool.execute(
      'SELECT voiceNoteFileName FROM feedback WHERE feedbackID = ?',
      [feedbackID]
    );

    if (feedback.length === 0) {
      feedbackLogger.warn('Feedback not found for voice note retrieval', { feedbackID });
      return res.status(404).json({ message: 'Feedback not found' });
    }

    if (!feedback[0].voiceNoteFileName) {
      feedbackLogger.info('No voice note found for feedback', { feedbackID });
      return res.status(404).json({ message: 'No voice note found for this feedback' });
    }

    // Return URL to backend proxy endpoint instead of direct B2 URL
    const voiceNoteUrl = `${process.env.BASE_URL || 'http://localhost:3000'}/v1/feedback/${feedbackID}/voice-note/stream`;

    feedbackLogger.info('Voice note URL generated successfully', { feedbackID });
    res.json({ voiceNotePath: voiceNoteUrl });
  } catch (error) {
    feedbackLogger.error(`Error getting voice note: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Stream voice note file (proxy from MinIO)
export const streamVoiceNoteFeedback = async (req, res) => {
  const { feedbackID } = req.params;

  try {
    const [feedback] = await pool.execute(
      'SELECT voiceNoteFileName FROM feedback WHERE feedbackID = ?',
      [feedbackID]
    );

    if (feedback.length === 0 || !feedback[0].voiceNoteFileName) {
      feedbackLogger.warn('Voice note not found for streaming', { feedbackID });
      return res.status(404).json({ message: 'Voice note not found' });
    }

    const fileName = feedback[0].voiceNoteFileName;
    const objectKey = `${VOICE_NOTE_PREFIX}/${fileName}`;

    feedbackLogger.info('Fetching voice note from MinIO', { feedbackID, fileName });

    // Fetch the object from MinIO
    const response = await minioClient.send(
      new GetObjectCommand({
        Bucket: MINIO_BUCKET,
        Key: objectKey,
      })
    );

    const stream = response.Body;

    // Set appropriate headers
    res.setHeader('Content-Type', response.ContentType || 'audio/wav');
    if (response.ContentLength) {
      res.setHeader('Content-Length', response.ContentLength);
    }
    res.setHeader('Accept-Ranges', 'bytes');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cache-Control', 'public, max-age=3600');

    // Stream the file to the client
    stream.pipe(res);

    feedbackLogger.info('Voice note streaming started', { feedbackID, fileName });
  } catch (error) {
    feedbackLogger.error(`Error streaming voice note: ${error.message}`, {
      error: error.stack,
      feedbackID,
    });
    if (!res.headersSent) {
      res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
};

// Delete voice note from feedback
export const deleteVoiceNoteFeedback = async (req, res) => {
  const { feedbackID } = req.params;

  try {
    const [feedback] = await pool.execute(
      'SELECT voiceNoteFileName FROM feedback WHERE feedbackID = ?',
      [feedbackID]
    );

    if (feedback.length === 0) {
      feedbackLogger.warn('Feedback not found for voice note deletion', { feedbackID });
      return res.status(404).json({ message: 'Feedback not found' });
    }

    if (!feedback[0].voiceNoteFileName) {
      feedbackLogger.info('No voice note to delete', { feedbackID });
      return res.status(404).json({ message: 'No voice note found for this feedback' });
    }

    // Delete from MinIO
    await deleteFromMinIO(feedback[0].voiceNoteFileName);

    // Update database
    await pool.execute(
      'UPDATE feedback SET voiceNotePath = NULL, voiceNoteFileName = NULL, voiceNoteDuration = NULL WHERE feedbackID = ?',
      [feedbackID]
    );

    feedbackLogger.info('Voice note deleted successfully', { feedbackID });
    res.status(200).json({ message: 'Voice note deleted successfully' });
  } catch (error) {
    feedbackLogger.error(`Error deleting voice note: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const downloadMarks = async (req, res) => {
  const { assignmentID, format } = req.params; // Get assignmentID and format (xlsx or csv)

  try {
    // First, get the assignment name
    const [assignmentInfo] = await pool.query(
      'SELECT assignName FROM assignment WHERE assignmentID = ?',
      [assignmentID]
    );

    if (assignmentInfo.length === 0) {
      feedbackLogger.warn(`Assignment not found: ${assignmentID}`);
      return res.status(404).json({ message: 'Assignment not found.' });
    }

    const assignmentName = assignmentInfo[0].assignName;

    // SQL query to fetch student data for the specific assignment
    // Use the same query structure as getAssignmentGradebookForStaff to ensure consistency
    const [rows] = await pool.query(
      `SELECT
          u.firstName AS StudentFirstName,
          u.lastName AS StudentLastName,
          u.username AS StudentUsername,
          f.comment AS FeedbackComment,
          f.mark AS Mark,
          a.assignTotalMarks AS TotalMarks,
          ROUND((f.mark / a.assignTotalMarks) * 100, 2) AS PercentageMark,
          CASE WHEN f.viewedAt IS NOT NULL THEN 'Yes' ELSE 'No' END AS FeedbackViewed
      FROM
          submission s
      INNER JOIN
          users u ON s.userID = u.userID
      INNER JOIN
          assignment a ON s.assignmentID = a.assignmentID
      INNER JOIN (
        SELECT f1.*
        FROM feedback f1
        INNER JOIN (
          SELECT submissionID, MAX(feedbackID) AS maxId
          FROM feedback
          GROUP BY submissionID
        ) lf ON lf.maxId = f1.feedbackID
      ) f ON f.submissionID = s.submissionID
      WHERE
          a.assignmentID = ?
      ORDER BY u.lastName, u.firstName;`,
      [assignmentID]
    );

    // Check if no data is returned
    if (rows.length === 0) {
      // Log warning if no data found (warning log)
      feedbackLogger.warn(`No data found for the given assignment: ${assignmentID}`);
      return res.status(404).json({ message: 'No data found for the given assignment.' });

    }

    // Create a safe filename by removing special characters and limiting length
    const safeFileName = assignmentName
      .replace(/[^a-zA-Z0-9\s-_]/g, '') // Remove special characters
      .replace(/\s+/g, '_')              // Replace spaces with underscores
      .substring(0, 50);                 // Limit length to 50 characters

    // Handle XLSX format
    if (format === 'xlsx') {
      const heading = [['Viewed', 'First Name', 'Last Name', 'Student No.', 'Comment', 'Mark', 'Total Marks', 'Percentage']];
      const workbook = XLSX.utils.book_new();
      const worksheet = XLSX.utils.json_to_sheet(rows);
      XLSX.utils.sheet_add_aoa(worksheet, heading, { origin: 'A1' });
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Student Marks');

      // Set column widths for better readability
      worksheet['!cols'] = [
        { wch: 10 },  // Viewed
        { wch: 15 },  // First Name
        { wch: 15 },  // Last Name
        { wch: 15 },  // Student No.
        { wch: 30 },  // Comment
        { wch: 10 },  // Mark
        { wch: 12 },  // Total Marks
        { wch: 12 }   // Percentage
      ];

      // Write the workbook to a buffer
      const buffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'buffer' });

      // Set response headers to download the XLSX file with assignment name
      res.setHeader('Content-Disposition', `attachment; filename="${safeFileName}_marks.xlsx"`);
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      // Log success if file generated (information log)
      feedbackLogger.info(`XLSX file generated successfully for assignment: ${assignmentID} (${assignmentName})`);
      return res.send(buffer);
    }

    // Handle CSV format
    else if (format === 'csv') {
      // Define the CSV fields
      const csvFields = ['FeedbackViewed', 'StudentFirstName', 'StudentLastName', 'StudentUsername', 'FeedbackComment', 'Mark', 'TotalMarks', 'PercentageMark'];
      const csv = parse(rows, { fields: csvFields });

      // Set response headers to download the CSV file with assignment name
      res.setHeader('Content-Disposition', `attachment; filename="${safeFileName}_marks.csv"`);
      res.setHeader('Content-Type', 'text/csv');

      // Log success if file generated (information log)
      feedbackLogger.info(`CSV file generated successfully for assignment: ${assignmentID} (${assignmentName})`);
      return res.send(csv);
    } 

    // If the format is not supported
    else {
      // Log warning for invalid format (warning log)
      feedbackLogger.warn(`Invalid format specified for download: ${format}`);
      return res.status(400).json({ message: 'Invalid format specified. Use either "xlsx" or "csv".' });

    }

  } catch (error) {
    // Log error when exporting marks fails (error log)
    feedbackLogger.error(`Error exporting marks ${error.message}`, { error });
    res.status(500).json({ message: 'Internal Server Error'});
  }
};