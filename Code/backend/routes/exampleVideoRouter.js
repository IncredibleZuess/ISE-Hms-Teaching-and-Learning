import express from 'express';
import verifyToken from '../middleware/verifyToken.js';
import { authorizeRoles } from '../middleware/authorization.js';
import {
  uploadExampleVideo,
  getExampleVideos,
  getExampleVideoUrl,
  deleteExampleVideo,
} from '../controllers/exampleVideoController.js';

const exampleVideoRouter = express.Router();

// All routes require token verification
exampleVideoRouter.use(verifyToken);

// Lecturer/Admin: upload an example video for an assignment
exampleVideoRouter.post(
  '/v1/assignments/:assignmentID/example-videos',
  authorizeRoles('Admin', 'Lecturer'),
  uploadExampleVideo
);

// Student/Lecturer/Admin: list all example videos for an assignment
exampleVideoRouter.get(
  '/v1/assignments/:assignmentID/example-videos',
  authorizeRoles('Admin', 'Lecturer', 'Student'),
  getExampleVideos
);

// Student/Lecturer/Admin: get a pre-signed playback URL (24-hour expiry)
exampleVideoRouter.get(
  '/v1/example-videos/:videoID/url',
  authorizeRoles('Admin', 'Lecturer', 'Student'),
  getExampleVideoUrl
);

// Lecturer/Admin: delete an example video (immediately revokes student access)
exampleVideoRouter.delete(
  '/v1/example-videos/:videoID',
  authorizeRoles('Admin', 'Lecturer'),
  deleteExampleVideo
);

export default exampleVideoRouter;