import multer from 'multer';  
import ffmpeg from 'fluent-ffmpeg';  
import fs from 'fs';  
import path from 'path';  
import pool from '../db.js';
import 'dotenv/config';
import { submissionLogger } from '../middleware/logger.js';
import minioClient from '../minioClient.js';
import { PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const MINIO_BUCKET = process.env.MINIO_BUCKET || 'student-videos';
const MINIO_PREFIX = 'HMS-Video-Uploads';

const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE);  


// Function to format the date using native JS Intl.DateTimeFormat
const formatDate = (date) => {
  const options = {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  };
  return new Intl.DateTimeFormat('en-GB', options).format(date).replace(',', ' at');
};

export const getSubmissionByAssignmentForUser = async (req, res) => {
  const { assignmentID } = req.params;
  const { userID } = req.user;

  submissionLogger.info(`[Start] Fetching submission for assignmentID: ${assignmentID} by userID: ${userID}`);

  try {
    submissionLogger.info(`[DB Query] Looking for submission in database`);
    const [submissions] = await pool.execute(
      `SELECT s.submissionID, s.submissionVidName, s.submissionVidPath, s.uploadedAt
       FROM submission s
       WHERE s.assignmentID = ? AND s.userID = ?`,
      [assignmentID, userID]
    );

    if (submissions.length === 0) {
      submissionLogger.warn(`[DB Result] No submission found for assignmentID: ${assignmentID}, userID: ${userID}`);
      return res.status(404).json({ message: 'No submission found for this assignment for the specified user.' });
    }

    const submission = submissions[0];
    submissionLogger.info(`[DB Result] Submission found: ${JSON.stringify(submission)}`);

    try {
      submissionLogger.info(`[Signed URL] Requesting signed URL for video: ${submission.submissionVidName}`);
      const signedUrl = await getVideoUrl(submission.submissionVidName);
      submissionLogger.info(`[Signed URL Success] Generated: ${signedUrl}`);

      const videoName = submission.submissionVidName.split('-').pop().split('.').shift();
      submissionLogger.info(`[Filename Extracted] Display name: ${videoName}`);

      res.json({
        submissionID: submission.submissionID,
        submissionVidName: videoName,
        submissionVidPath: signedUrl,
        uploadedAt: submission.uploadedAt,
      });

      submissionLogger.info(`[End] Submission successfully sent for assignmentID: ${assignmentID}, userID: ${userID}`);
    } catch (err) {
      submissionLogger.error(`[Signed URL Error] Could not generate signed URL for ${submission.submissionVidName}: ${err.message}`, { err });
      return res.status(500).json({ message: 'Failed to generate video download link.' });
    }
  } catch (error) {
    submissionLogger.error(`[Error] Unexpected error during submission fetch: ${error.message}`, { error });
    res.status(500).json({ message: 'An error occurred while fetching the submission.' });
  }
};



// Function to get submissions that are "To be marked" (without feedback)
export const getNotMarkedSubmissions = async (req, res) => {
  const { assignmentID } = req.params; // Get assignmentID from the request params

  // log information on fetching unmarked submissions for an assignment (information log)
  submissionLogger.info(`Fetching unmarked submissions for assignmentID: ${assignmentID}`);
  try {
    // Query to get submissions that don't have feedback (i.e., "To be marked"), including total marks for the assignment
    const [rows] = await pool.execute(
      `SELECT s.submissionID, u.firstName, u.lastName, u.username, s.submissionVidName, s.submissionVidPath, s.uploadedAt, a.assignTotalMarks
       FROM submission s
       JOIN users u ON s.userID = u.userID
       LEFT JOIN feedback f ON s.submissionID = f.submissionID
       JOIN assignment a ON s.assignmentID = a.assignmentID
       WHERE s.assignmentID = ? AND f.submissionID IS NULL`,
      [assignmentID]
    );

    // Format the submission list
    const submission = rows.map(submission => ({
      submissionID: submission.submissionID,
      studentName: `${submission.firstName} ${submission.lastName} (${submission.username})`,
      submissionVidName: submission.submissionVidName,
      submissionVidPath: submission.submissionVidPath,
      uploadedAt: formatDate(new Date(submission.uploadedAt)), // Use formatDate function
      totalMarks: submission.assignTotalMarks, // Include total marks for the assignment
    }));

    // log successfully fetching unmarked submissions for an assignment (information log)
    submissionLogger.info(`Successfully fetched unmarked submissions for assignmentID: ${assignmentID}`);
    res.json({ submission });
  } catch (error) {
    // log any errors that may have occurred while fetching unmarked submissions for an assignment (error log)
    submissionLogger.error(`Error fetching unmarked submissions: ${error.message}`, { error });
    res.status(500).json({ message: 'Error fetching submissions to be marked.' });
  }
};



// Get "Marked" submissions WITH feedback.viewedAt so lecturers can see if student opened it
export const getMarkedSubmissions = async (req, res) => {
  const { assignmentID } = req.params;
  const { userID, userType } = req.user;

  const isStaff = userType === 'Admin' || userType === 'Lecturer';

  try {
    const params = [assignmentID];
    let where = 's.assignmentID = ?';

    if (!isStaff) {
      where += ' AND s.userID = ?';
      params.push(userID);
    }

    // IMPORTANT: join assignment (for total marks) and alias a flat shape
    const [rows] = await pool.query(
      `
      SELECT
        s.submissionID,
        s.submissionVidName,
        s.submissionVidPath,
        s.uploadedAt,
        a.assignTotalMarks        AS totalMarks,
        CONCAT(u.firstName, ' ', u.lastName, ' (', u.username, ')') AS studentName,
        f.feedbackID,
        f.mark,
        f.comment,
        f.feedbackViewed,
        f.viewedAt
      FROM submission s
      JOIN users u       ON u.userID = s.userID
      JOIN assignment a  ON a.assignmentID = s.assignmentID
      JOIN feedback f    ON f.submissionID = s.submissionID
      WHERE ${where}
      ORDER BY s.uploadedAt DESC
      `,
      params
    );

    // Match the exact structure used by the Flutter client
    const submission = rows.map(r => ({
      submissionID: r.submissionID,
      studentName: r.studentName,
      submissionVidName: r.submissionVidName,
      submissionVidPath: r.submissionVidPath,
      uploadedAt: formatDate(new Date(r.uploadedAt)), // same formatting as not-marked
      totalMarks: r.totalMarks,
      // keep these too (used by grade/edit flows)
      feedbackID: r.feedbackID,
      mark: r.mark,
      comment: r.comment,
      feedbackViewed: Boolean(r.feedbackViewed), // Convert MySQL TINYINT to boolean
      viewedAt: r.viewedAt,
    }));

    submissionLogger.info(`[End] Successfully processed ${submission.length} marked submissions`);
    return res.status(200).json({ submission });
  } catch (error) {
    submissionLogger?.error?.(`Error fetching marked submissions: ${error.message}`, { error });
    return res.status(500).json({ message: 'Internal server error' });
  }
};









 
// Ensure 'uploads' directories exist
if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads');
  // Log creation of directory (information log)
  submissionLogger.info('Uploads directory created');
}

// Multer configuration for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
      cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substring(7);
    
    // Extract vidName from request body
    const { vidName } = req.body; 

    if (!vidName) {
        // Log a warning if vidName is missing and use a default name
        submissionLogger.warn('vidName not provided in request, using default value.');
        const sanitizedVidName = 'defaultVidName'; // Fallback if vidName is missing
        const newFileName = `${timestamp}-${randomString}-${sanitizedVidName}.mp4`;
        cb(null, newFileName);
    } else {
        const sanitizedVidName = vidName.replace(/[^a-zA-Z0-9-_]/g, ''); // Remove invalid characters
        const newFileName = `${timestamp}-${randomString}-${sanitizedVidName}.mp4`;
        cb(null, newFileName);
    }
  },
});

const upload = multer({ storage });

 
// Video compression function
const compressVideo = (filePath, outputFilePath, maxFileSize) => {
  const newOutputFilePath = outputFilePath.replace(/([^\/]+)$/, '1$1');

  return new Promise((resolve, reject) => {
    ffmpeg(filePath)
      .output(newOutputFilePath)
      .videoCodec('libx264')
      .size('?x360') // Rezize the height but maintain aspect ratio
      .videoBitrate('800k')
      .audioBitrate('128k')
      .outputOptions('-crf 23')  // Medium compression
      .on('end', async () => {
        try {
          // Check if the compressed file size exceeds the maximum allowed size because very large files might need to be compressed more than once
          const compressedSize = fs.statSync(newOutputFilePath).size;
          if (compressedSize > maxFileSize) {
            // Log warning if file exceeds maximum size (warning log)
            submissionLogger.warn('Compressed file still exceeds the maximum size.');
            return reject(new Error('Compressed file size exceeds the maximum allowed size'));
          }

          // Log success for video compression (information log)
          submissionLogger.info(`Video compressed successfully: ${newOutputFilePath}`);
          // If compressed size is within the limit, promise is resolved
          resolve(newOutputFilePath);
        } catch (err) {
          // Log error when compression fails (error log)
          submissionLogger.error(`Error during compression size check: ${err.message}`, { err });
          reject(err);
        }
      })
      .on('error', (err) => {
        // Log error when compression fails (error log)
        submissionLogger.error(`FFmpeg error during compression: ${err.message}`, { err });
        reject(err);
      })
      .run();
  });
};
 
 
// Check video type and convert to .mp4 if necessary
const convertToMp4 = (filePath, outputFilePath) => {
  return new Promise((resolve, reject) => {
    ffmpeg(filePath)
      .output(outputFilePath)
      .videoCodec('libx264')
      .on('end', () => {
        // Log video conversion (information log)
        submissionLogger.info(`Video converted to MP4: ${outputFilePath}`);
        resolve(outputFilePath);
      })
      .on('error', (err) => {
        // Log error when conversion fails (error log)
        submissionLogger.error(`Error during video conversion:`,  err );
        reject(err);
      })
      .run();
  });
};


// Upload video to MinIO
const uploadToMinIO = async (filePath) => {
  const fileName = path.basename(filePath);
  const fileBuffer = fs.readFileSync(filePath);
  const objectKey = `${MINIO_PREFIX}/${fileName}`;

  try {
    await minioClient.send(
      new PutObjectCommand({
        Bucket: MINIO_BUCKET,
        Key: objectKey,
        Body: fileBuffer,
        ContentType: 'video/mp4',
      })
    );

    submissionLogger.info(`Uploaded to MinIO: ${objectKey} (bucket: ${MINIO_BUCKET})`);
    return objectKey;
  } catch (err) {
    submissionLogger.error(`MinIO upload failed: ${err.message}`, { err });
    throw err;
  }
};

// Retrieve signed URL for a video stored in MinIO
const getVideoUrl = async (videoId) => {
  const objectKey = `${MINIO_PREFIX}/${videoId}`;

  try {
    const command = new GetObjectCommand({
      Bucket: MINIO_BUCKET,
      Key: objectKey,
    });

    // 24-hour expiry
    const signedUrl = await getSignedUrl(minioClient, command, { expiresIn: 86400 });
    submissionLogger.info(`Generated MinIO signed URL for videoId: ${videoId}`);
    return signedUrl;
  } catch (error) {
    submissionLogger.error(`Failed to generate MinIO signed URL: ${error.message}`, { error });
    throw new Error(`Failed to generate MinIO signed download link`);
  }
};

// Delete an object from MinIO
const deleteObjectFromMinIO = async (objectKey) => {
  const fullKey = `${MINIO_PREFIX}/${path.basename(objectKey)}`;

  try {
    await minioClient.send(
      new DeleteObjectCommand({
        Bucket: MINIO_BUCKET,
        Key: fullKey,
      })
    );

    submissionLogger.info(`Successfully deleted object from MinIO: ${fullKey}`);
  } catch (error) {
    submissionLogger.error(`Error deleting object from MinIO: ${error.message}`, { error });
    throw new Error(`Failed to delete object from MinIO: ${error.message}`);
  }
};
 
 
// Store video metadata (public video link) in MySQL
const storeMetadata = async (req, res, assignmentID, submissionVidName, submissionVidPath ) => {
  try{
    const { userID } = req.user;
 
    const query = 'INSERT INTO submission (assignmentID, userID, submissionVidName, submissionVidPath) VALUES (?, ?, ?, ?)';
 
    await pool.execute(query, [assignmentID, userID, submissionVidName, submissionVidPath]);
    // Log success when metadata stored (information log)
    submissionLogger.info(`Metadata stored for userID: ${userID}, assignmentID: ${assignmentID}`);
  } catch (error) {
    // Log error when metadata storing fails (error log)
    submissionLogger.error(`Error during metadata storing: ${error.message}`, { error });
    if (!res.headersSent) { return res.status(500).json({ message: 'Failed to store metadata', details: error.message }); }
  }
}
 
 
// Delete the old video from MinIO
const deleteOldVideoFromMinIO = async (oldVideoPath) => {
  const fileName = path.basename(oldVideoPath.replace(/^\/|\\/, ''));
  return deleteObjectFromMinIO(fileName);
};
 
 
// Update video metadata in MySQL
const updateMetadata = async (req, res, assignmentID, newVideoId, publicLink) => {
  try {
    const { userID } = req.user;
 
    const query = 'UPDATE submission SET submissionVidName = ?, submissionVidPath = ? WHERE assignmentID = ? AND userID = ?';
 
    await pool.execute(query, [newVideoId, publicLink, assignmentID, userID]);
    // Log success when video metadata updated
    submissionLogger.info(`Successfully updated video metadata for assignmentID: ${assignmentID}, userID: ${userID}, newVideoId: ${newVideoId}`); 
  } catch (error) {
    // Log error when updating metadata fails (error log)
    submissionLogger.error(`Error during metadata update for assignmentID: ${assignmentID}, userID: ${userID}, newVideoId: ${newVideoId}. Error: ${error.message}`, { error }); 
    if (!res.headersSent) {
      return res.status(500).json({ message: 'Failed to update metadata', details: error.message });
    }
  }
};
 



// Main function to handle video upload and compression
export const uploadVideo = (req, res) => {
  upload.single('video')(req, res, async (err) => {
    if (err instanceof multer.MulterError) {
      // Log error when file upload fails (error log)
      submissionLogger.error(`File upload error: ${err.message}`, { err });
      return res.status(500).json({ message: 'File upload error', details: err.message });
    } else if (err) {
      // Log error when file upload fails (error log)
      submissionLogger.error(`Unexpected error during file upload: ${err.message}`, { err });
      return res.status(500).json({ message: 'Unexpected error during file upload', details: err.message });
    }

    // Log passed first check
    submissionLogger.info('Passed 1');
 
    if (!req.file) {
      // Log warning when no file is uploaded (warning log)
      submissionLogger.warn('No file uploaded');
      return res.status(400).json({ message: 'No file uploaded' });
    }
 
    // Extract assignmentID from the request body
    const { assignmentID } = req.body;

    if (!assignmentID) {
      // Log warning for missing field (warning log)
      submissionLogger.warn('Assignment ID is required');
      return res.status(400).json({ message: 'Assignment ID is required' });
    }

    // Check if assignment due date has passed
    try {
      const [assignment] = await pool.execute(
        'SELECT assignDueDate FROM assignment WHERE assignmentID = ?',
        [assignmentID]
      );

      if (assignment.length === 0) {
        submissionLogger.warn(`Assignment not found: ${assignmentID}`);
        // Clean up uploaded file
        if (req.file && req.file.path) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(404).json({ message: 'Assignment not found' });
      }

      const dueDate = new Date(assignment[0].assignDueDate);
      const now = new Date();

      if (now > dueDate) {
        submissionLogger.warn(`Submission attempt after due date for assignmentID: ${assignmentID}`);
        // Clean up uploaded file
        if (req.file && req.file.path) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(400).json({
          message: 'Submission deadline has passed',
          dueDate: dueDate.toISOString()
        });
      }
    } catch (error) {
      submissionLogger.error(`Error checking assignment due date: ${error.message}`, { error });
      // Clean up uploaded file
      if (req.file && req.file.path) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(500).json({ message: 'Error validating assignment due date' });
    }

    const filePath = req.file.path;
    const fileSize = req.file.size;
    const ext = path.extname(filePath).toLowerCase();  // Get file extension for extension type check
    let finalFilePath = filePath;
    let videoId;

    // Log information on file upload (information log)
    submissionLogger.info(`File uploaded: ${filePath}, size: ${fileSize} bytes, extension: ${ext}`);
    // Log information on assignmentID (information log)
    submissionLogger.info(`Assignment ID: ${assignmentID}`);
 
    try {
      // If file is not .mp4, then convert it to .mp4
      if (ext !== '.mp4') {
        const mp4FilePath = `uploads/${path.basename(filePath, path.extname(filePath))}.mp4`;
        finalFilePath = await convertToMp4(filePath, mp4FilePath);
        // Log file conversion (information log)
        submissionLogger.info(`Converting file: ${filePath} to MP4 format.`);
        fs.unlinkSync(filePath);  // Delete the original non-mp4 file after conversion
        // Log original file deletion (information log)
        submissionLogger.info(`Deleted original file: ${filePath}`);
      }

      // Log information on file size (information log)
      submissionLogger.info(`File size: ${fileSize} bytes`);

 
      // If the file exceeds the maximum allowed size, then compress it
      if (fileSize > MAX_FILE_SIZE) {
        // Log convertion to .mp4 (information log)
        submissionLogger.info(`Converting file to .mp4: ${filePath}`);
        const compressedFilePath = `uploads/${path.basename(filePath, path.extname(filePath))}.mp4`;
        finalFilePath = await compressVideo(filePath, compressedFilePath, MAX_FILE_SIZE);
 
        // Delete the original file after successful compression
        fs.unlinkSync(filePath);
        // Log success for compression (information log)
        submissionLogger.info(`Compression complete. New file path: ${finalFilePath}`);
      }

// Log information on final file path (information log)
      submissionLogger.info(`Final file path: ${finalFilePath}`);
  
      // Upload the (compressed or original) video to MinIO
      const minioKey = await uploadToMinIO(finalFilePath);
  
      videoId = path.basename(minioKey); // Get the videoId from the MinIO object key
      // Log success for uploading video (information log)
      submissionLogger.info(`Uploaded video to MinIO. videoId: ${videoId}, minioKey: ${minioKey}`);
      // Get signed URL
      const publicLink = await getVideoUrl(videoId);
      // Log success for public link generation (information og)
      submissionLogger.info(`Generated signed URL: ${publicLink}`);
      // Store video metadata in the database, including assignmentID
      await storeMetadata(req, res, assignmentID, videoId, publicLink);
      // Log success for stored metadata (information log)
      submissionLogger.info(`Stored video metadata for assignmentID: ${assignmentID}, videoId: ${videoId}`);
      // Delete the local file after uploading to MinIO
      fs.unlinkSync(finalFilePath);

      // log success for deletion of local file (information log)
      submissionLogger.info(`Local file deleted: ${finalFilePath}`);
      
      res.status(200).json({ message: 'File uploaded successfully', publicLink });
      // Log success for file upload (information log)
      submissionLogger.info(`File upload successful for assignmentID: ${assignmentID}. Public link: ${publicLink}`);
    } catch (error) {
      // Log error when video processing fails (error log)
      submissionLogger.error(`Error during video processing: ${error.message}`, { error });
      res.status(500).json({ message: 'Failed to process video', details: error.message });
    } finally {
      // Ensures that local file is always cleaned up
      if (fs.existsSync(finalFilePath)) {
        fs.unlinkSync(finalFilePath);
        // Log success when local file cleaned (information log)
        submissionLogger.info(`Cleaned up local file: ${finalFilePath}`);
      }
    }
  });
};
 



// Main function to handle video update
export const updateVideo = (req, res) => {
  upload.single('video')(req, res, async (err) => {
    if (err instanceof multer.MulterError) {
      // Log error when file upload fails (error log)
      submissionLogger.error(`File upload error: ${err.message}`, { err });
      return res.status(500).json({ message: 'File upload error', details: err.message });
    } else if (err) {
      // Log error when file upload fails unexpectedly (error log)
      submissionLogger.error(`Unexpected error during file upload: ${err.message}`, { err });
      return res.status(500).json({ message: 'Unexpected error during file upload', details: err.message });
    }
 
    if (!req.file) {
      // Log warning for no file uploaded (warning log)
      submissionLogger.warn('No file uploaded');
      return res.status(400).json({ message: 'No file uploaded' });
    }
 
    // Extract assignmentID and oldVideoName from the request body
    const { assignmentID, oldVideoName } = req.body;
 
    if (!assignmentID) {
      // Log warning for missing fields (warning log)
      submissionLogger.warn('Assignment ID is required');
      return res.status(400).json({ message: 'Assignment ID is required' });
    }
 
    const filePath = req.file.path;
    const fileSize = req.file.size;
    const ext = path.extname(filePath).toLowerCase();  // Get file extension for extension type check
    let finalFilePath = filePath;
    let newVideoId;
 
    try {
      const { userID } = req.user;
 
      // Retrieve the old video name from the database
      const query = 'SELECT submissionVidName FROM submission WHERE assignmentID = ? AND userID = ?';
      const [rows] = await pool.execute(query, [assignmentID, userID]);
 
      if (rows.length === 0) {
        // Log warning for no video found (warning log)
        submissionLogger.warn(`No video found for assignmentID: ${assignmentID} and userID: ${userID}`);
        return res.status(404).json({ message: 'No video found for the given assignment ID' });
      }
 
      const oldVideoName = rows[0].submissionVidName; // Get the old video name
      // Log success for old video found (informatuon log)
      submissionLogger.info(`Found old video: ${oldVideoName}`);
      // Check if the old video exists in MinIO and delete it
      await deleteOldVideoFromMinIO(oldVideoName);
      // Log success for old video deletion (information log)
      submissionLogger.info(`Deleted old video from MinIO: ${oldVideoName}`);
      // If file is not .mp4, convert it to .mp4
      if (ext !== '.mp4') {
        const mp4FilePath = `uploads/${path.basename(filePath, path.extname(filePath))}.mp4`;
        finalFilePath = await convertToMp4(filePath, mp4FilePath);
        fs.unlinkSync(filePath);  // Delete the original non-mp4 file after conversion
        // Log success for file conversion (information log)
        submissionLogger.info(`Converted file to .mp4: ${finalFilePath}`);
      }
 
      // If the file exceeds the maximum allowed size, then compress it
      if (fileSize > MAX_FILE_SIZE) {
        const compressedFilePath = `uploads/${path.basename(filePath, path.extname(filePath))}.mp4`;
        finalFilePath = await compressVideo(finalFilePath, compressedFilePath, MAX_FILE_SIZE);
 
        // Delete the original file after successful compression
        fs.unlinkSync(filePath);
        // Log success for file compression (information log)
        submissionLogger.info(`Compressed file: ${finalFilePath}`);
      }
 
// Upload the (compressed or original) video to MinIO
      const minioKey = await uploadToMinIO(finalFilePath);

      newVideoId = path.basename(minioKey); // Get the new videoId from the MinIO object key
      // Log success for uploaded video (information log)
      submissionLogger.info(`Uploaded new video to MinIO: ${minioKey}`);

      const publicLink = await getVideoUrl(newVideoId);
      // Log success for public link generation (information log)
      submissionLogger.info(`Generated signed URL: ${publicLink}`);

      // Update video metadata in the database
      await updateMetadata(req, res, assignmentID, newVideoId, publicLink);
      // Log success for metadata update (information log)
      submissionLogger.info(`Updated metadata for assignmentID: ${assignmentID}, newVideoId: ${newVideoId}`);

      // Delete the local file after uploading to MinIO
      fs.unlinkSync(finalFilePath);
      // Log success for deletion of local file (information log)
      submissionLogger.info(`Deleted local file: ${finalFilePath}`);
      
      res.status(200).json({ message: 'File updated successfully', publicLink });
      // Log success for file update (information log)
      submissionLogger.info(`File update successful for assignmentID: ${assignmentID}. Public link: ${publicLink}`);

    } catch (error) {
      // Log error when video update fails (error log)
      submissionLogger.error(`Error during video update: ${error.message}`, { error });
      res.status(500).json({ message: 'Failed to update video', details: error.message });
    } finally {
      // Ensures that local file is always cleaned up
      if (fs.existsSync(finalFilePath)) {
        fs.unlinkSync(finalFilePath);
        // Log success when local file cleaned (information log)
        submissionLogger.info(`Cleaned up local file: ${finalFilePath}`);
      }
    }
  });
};
