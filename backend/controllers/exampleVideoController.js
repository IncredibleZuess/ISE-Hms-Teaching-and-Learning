import multer from 'multer';
import path from 'path';
import pool from '../db.js';
import 'dotenv/config';
import { exampleVideoLogger } from '../middleware/logger.js';
import minioClient from '../minioClient.js';
import { PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const MINIO_BUCKET = process.env.MINIO_BUCKET_EXAMPLES || 'example-videos';
const MAX_EXAMPLE_VIDEO_SIZE = parseInt(process.env.MAX_EXAMPLE_VIDEO_SIZE || String(500 * 1024 * 1024));

const ALLOWED_MIME_TYPES = [
  'video/mp4',
  'video/quicktime',
  'video/x-msvideo',
  'video/webm',
];
const ALLOWED_EXTENSIONS = ['.mp4', '.mov', '.avi', '.webm'];

// Multer config: memory storage so we can stream straight to MinIO
const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: MAX_EXAMPLE_VIDEO_SIZE },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      return cb(new Error(`Unsupported file extension '${ext}'. Allowed: MP4, MOV, AVI, WEBM`));
    }
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      return cb(new Error(`Unsupported MIME type '${file.mimetype}'. Allowed: MP4, MOV, AVI, WEBM`));
    }
    cb(null, true);
  },
});

// POST /v1/assignments/:assignmentID/example-videos (Lecturer/Admin)
export const uploadExampleVideo = (req, res) => {
  upload.single('video')(req, res, async (err) => {
    if (err instanceof multer.MulterError) {
      exampleVideoLogger.error(`Example video upload error: ${err.message}`, { err });
      return res.status(400).json({ message: err.message });
    } else if (err) {
      exampleVideoLogger.error(`Example video upload rejected: ${err.message}`, { err });
      return res.status(400).json({ message: err.message });
    }

    try {
      const { assignmentID } = req.params;
      const { title, description } = req.body;

      if (!assignmentID) {
        return res.status(400).json({ message: 'assignmentID is required' });
      }
      if (!title || String(title).trim() === '') {
        return res.status(400).json({ message: 'A title is required for the example video' });
      }
      if (!req.file) {
        return res.status(400).json({ message: 'No video file uploaded' });
      }

      // Verify assignment exists
      const [assignmentRows] = await pool.execute(
        'SELECT assignmentID FROM assignment WHERE assignmentID = ?',
        [assignmentID]
      );
      if (assignmentRows.length === 0) {
        return res.status(404).json({ message: 'Assignment not found' });
      }

      const originalName = path.basename(req.file.originalname || 'video');
      const objectKey = `${assignmentID}/${Date.now()}-${Math.random().toString(36).substring(2, 8)}-${originalName}`;
      const fullKey = `${objectKey}`;

      // Stream to MinIO
      await minioClient.send(
        new PutObjectCommand({
          Bucket: MINIO_BUCKET,
          Key: fullKey,
          Body: req.file.buffer,
          ContentType: req.file.mimetype,
          ContentLength: req.file.size,
        })
      );

      // Store metadata
      const [result] = await pool.execute(
        `INSERT INTO example_videos (assignment_id, title, description, minio_key, file_size, uploaded_by)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [assignmentID, String(title).trim(), description || null, fullKey, req.file.size, req.user.userID]
      );

      exampleVideoLogger.info(`Example video uploaded for assignmentID: ${assignmentID} (id: ${result.insertId})`);
      res.status(201).json({
        message: 'Example video uploaded successfully',
        video: { id: result.insertId, title: String(title).trim(), description: description || null },
      });
    } catch (error) {
      exampleVideoLogger.error(`Error uploading example video: ${error.message}`, { error });
      res.status(500).json({ message: 'Failed to upload example video' });
    }
  });
};

// GET /v1/assignments/:assignmentID/example-videos (Student/Lecturer/Admin)
export const getExampleVideos = async (req, res) => {
  const { assignmentID } = req.params;

  try {
    const [rows] = await pool.execute(
      `SELECT ev.id, ev.title, ev.description, ev.minio_key, ev.file_size, ev.created_at,
              u.firstName, u.lastName
       FROM example_videos ev
       LEFT JOIN users u ON u.userID = ev.uploaded_by
       WHERE ev.assignment_id = ?
       ORDER BY ev.created_at DESC`,
      [assignmentID]
    );

    return res.json({
      assignmentId: Number(assignmentID),
      videos: rows.map((r) => ({
        id: r.id,
        title: r.title,
        description: r.description,
        fileSize: r.file_size,
        createdAt: r.created_at,
        uploadedBy: r.firstName ? `${r.firstName} ${r.lastName}` : null,
      })),
    });
  } catch (error) {
    exampleVideoLogger.error(`Error listing example videos: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to list example videos' });
  }
};

// GET /v1/example-videos/:videoID/url (Student/Lecturer/Admin) - pre-signed playback URL (24h)
export const getExampleVideoUrl = async (req, res) => {
  const { videoID } = req.params;

  try {
    const [rows] = await pool.execute(
      'SELECT minio_key FROM example_videos WHERE id = ?',
      [videoID]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Example video not found' });
    }

    const command = new GetObjectCommand({ Bucket: MINIO_BUCKET, Key: rows[0].minio_key });
    const url = await getSignedUrl(minioClient, command, { expiresIn: 86400 }); // 24 hours

    res.json({ url });
  } catch (error) {
    exampleVideoLogger.error(`Error generating example video URL: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to generate example video URL' });
  }
};

// DELETE /v1/example-videos/:videoID (Lecturer/Admin)
export const deleteExampleVideo = async (req, res) => {
  const { videoID } = req.params;

  try {
    const [rows] = await pool.execute(
      'SELECT id, minio_key FROM example_videos WHERE id = ?',
      [videoID]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Example video not found' });
    }

    // Delete from MinIO first
    try {
      await minioClient.send(
        new DeleteObjectCommand({ Bucket: MINIO_BUCKET, Key: rows[0].minio_key })
      );
    } catch (err) {
      exampleVideoLogger.warn(`MinIO delete failed for ${rows[0].minio_key}: ${err.message}`);
    }

    // Delete metadata row
    await pool.execute('DELETE FROM example_videos WHERE id = ?', [videoID]);

    exampleVideoLogger.info(`Example video deleted: id ${videoID}`);
    res.json({ message: 'Example video deleted successfully' });
  } catch (error) {
    exampleVideoLogger.error(`Error deleting example video: ${error.message}`, { error });
    res.status(500).json({ message: 'Failed to delete example video' });
  }
};