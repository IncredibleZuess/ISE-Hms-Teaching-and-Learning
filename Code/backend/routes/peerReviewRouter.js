import express from 'express';
import verifyToken from '../middleware/verifyToken.js';
import { authorizeRoles } from '../middleware/authorization.js';
import {
  configurePeerReview,
  getPeerReviewConfig,
  getAssignedReviews,
  submitPeerReview,
  getPeerReviewResults,
  getAllPeerReviews,
  overridePeerReviewScore,
} from '../controllers/peerReviewController.js';

const peerReviewRouter = express.Router();

// All routes require token verification
peerReviewRouter.use(verifyToken);

// Lecturer/Admin: create/update peer review configuration for an assignment
peerReviewRouter.post(
  '/v1/assignments/:assignmentID/peer-review/config',
  authorizeRoles('Admin', 'Lecturer'),
  configurePeerReview
);

// Student/Lecturer/Admin: fetch the active peer review config + rubric
peerReviewRouter.get(
  '/v1/assignments/:assignmentID/peer-review/config',
  authorizeRoles('Admin', 'Lecturer', 'Student'),
  getPeerReviewConfig
);

// Student: fetch list of assigned peers' submissions to review
peerReviewRouter.get(
  '/v1/assignments/:assignmentID/peer-review/my-reviews',
  authorizeRoles('Admin', 'Lecturer', 'Student'),
  getAssignedReviews
);

// Student: submit a completed peer review
peerReviewRouter.post(
  '/v1/peer-reviews/:assignmentID',
  authorizeRoles('Student'),
  submitPeerReview
);

// Student: view own peer review results (after deadline)
peerReviewRouter.get(
  '/v1/assignments/:assignmentID/peer-review/results',
  authorizeRoles('Admin', 'Lecturer', 'Student'),
  getPeerReviewResults
);

// Lecturer/Admin: view all peer review submissions for an assignment
peerReviewRouter.get(
  '/v1/assignments/:assignmentID/peer-review/all',
  authorizeRoles('Admin', 'Lecturer'),
  getAllPeerReviews
);

// Lecturer/Admin: override a peer review score
peerReviewRouter.patch(
  '/v1/peer-reviews/:reviewID/override',
  authorizeRoles('Admin', 'Lecturer'),
  overridePeerReviewScore
);

export default peerReviewRouter;