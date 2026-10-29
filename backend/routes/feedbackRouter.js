import express from 'express';
import verifyToken from '../middleware/verifyToken.js';
import { authorizeRoles } from '../middleware/authorization.js'; // Import the authorization middleware
import {
  getFeedback,
  addFeedback,
  updateFeedback,
  deleteFeedback,
  getStudentMarksByUserAndModule,
  getModuleMarksForStaff,
  getAssignmentGradebookForStaff,
  downloadMarks,
  markFeedbackAsViewed,
  markFeedbackViewed,
  uploadVoiceNoteFeedback,
  getVoiceNoteFeedback,
  streamVoiceNoteFeedback,
  deleteVoiceNoteFeedback
} from '../controllers/feedbackController.js';

const feedbackRoute = express.Router();

// All routes should check for a valid token
feedbackRoute.use(verifyToken);

// IMPORTANT: Gradebook routes MUST come before the generic :submissionID route
// to prevent route parameter collision

// Get staff gradebook for all students in a module (Admins or Lecturers)
feedbackRoute.get('/v1/feedback/:moduleID/gradebook-staff', authorizeRoles('Admin', 'Lecturer'), getModuleMarksForStaff);

// Get staff gradebook for a specific assignment (Admins or Lecturers)
feedbackRoute.get('/v1/feedback/assignment/:assignmentID/gradebook-staff', authorizeRoles('Admin', 'Lecturer'), getAssignmentGradebookForStaff);

// Get student feedback for Gradebook (for the authenticated user's own marks)
feedbackRoute.get('/v1/feedback/:moduleID/gradebook', authorizeRoles('Admin', 'Lecturer', 'Student'), getStudentMarksByUserAndModule);

// Get feedback (Admins, Lecturers, or Students - students can only view their own)
feedbackRoute.get('/v1/feedback/:submissionID', authorizeRoles('Admin', 'Lecturer', 'Student'), getFeedback);

// Add feedback (Admins or Lecturers)
feedbackRoute.post('/v1/feedback', authorizeRoles('Admin', 'Lecturer'), addFeedback);

// Update feedback (Admins or Lecturers)
feedbackRoute.put('/v1/feedback/:feedbackID', authorizeRoles('Admin', 'Lecturer'), updateFeedback);

// Delete feedback (Admins or Lecturers)
feedbackRoute.delete('/v1/feedback/:feedbackID', authorizeRoles('Admin', 'Lecturer'), deleteFeedback);

// Mark feedback as viewed (Students only)
feedbackRoute.post('/v1/feedback/:feedbackID/viewed', authorizeRoles('Student'), markFeedbackAsViewed);

// Mark feedback as viewed by student (alternative endpoint using PUT)
feedbackRoute.put('/v1/feedback/:feedbackID/viewed', authorizeRoles('Student'), markFeedbackViewed);

// Route for downloading feedback in specific format (Admins or Lecturers)
feedbackRoute.get('/v1/download-marks/:assignmentID/:format', authorizeRoles('Admin', 'Lecturer'), downloadMarks);

// Voice Note Routes
// Upload voice note for feedback (Admins or Lecturers)
feedbackRoute.post('/v1/feedback/:feedbackID/voice-note', authorizeRoles('Admin', 'Lecturer'), uploadVoiceNoteFeedback);

// Get voice note for feedback (Admins, Lecturers, or Students)
feedbackRoute.get('/v1/feedback/:feedbackID/voice-note', authorizeRoles('Admin', 'Lecturer', 'Student'), getVoiceNoteFeedback);

// Stream voice note file (proxy from B2) - Public endpoint (authorization checked when URL is generated)
// Must be defined BEFORE the verifyToken middleware so it doesn't require auth
const streamRouter = express.Router();
streamRouter.get('/v1/feedback/:feedbackID/voice-note/stream', streamVoiceNoteFeedback);

// Delete voice note from feedback (Admins or Lecturers)
feedbackRoute.delete('/v1/feedback/:feedbackID/voice-note', authorizeRoles('Admin', 'Lecturer'), deleteVoiceNoteFeedback);

export { streamRouter };

export default feedbackRoute;