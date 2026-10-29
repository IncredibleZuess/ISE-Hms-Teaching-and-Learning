import express from 'express';
import verifyToken from '../middleware/verifyToken.js'; // Middleware to check JWT
import { authorizeRoles } from '../middleware/authorization.js'; // Import the authorization middleware
import { getAllUsers, getUserInfo, createUser, updateUser, deleteUser, downloadBulkUploadTemplate, bulkUploadUsers, bulkUploadPreview, bulkUploadConfirm } from '../controllers/adminController.js';
import multer from 'multer';

const adminRoute = express.Router();

// Configure multer for file uploads (store in memory)
const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    // Phase 2: accept ONLY .xlsx per FR-EU-02 (reject .csv, .xls, etc.)
    if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      cb(null, true);
    } else {
      cb(new Error('Only .xlsx Excel files are allowed'));
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

// All routes require token verification and admin authorization
adminRoute.use(verifyToken);

// IMPORTANT: Specific routes must come BEFORE parameterized routes to avoid conflicts

// GET download bulk upload template (Admin and Lecturer)
adminRoute.get('/v1/admin/bulk-upload/template', authorizeRoles('Admin', 'Lecturer'), downloadBulkUploadTemplate);

// POST bulk upload preview - parse + validate .xlsx, return preview payload (Admin and Lecturer)
adminRoute.post('/v1/admin/bulk-upload/preview', authorizeRoles('Admin', 'Lecturer'), upload.single('file'), bulkUploadPreview);

// POST bulk upload confirm - execute import for a preview session (Admin and Lecturer)
adminRoute.post('/v1/admin/bulk-upload/confirm', authorizeRoles('Admin', 'Lecturer'), bulkUploadConfirm);

// POST bulk upload users from Excel (Admin and Lecturer) - legacy direct import
adminRoute.post('/v1/admin/bulk-upload/users', authorizeRoles('Admin', 'Lecturer'), upload.single('file'), bulkUploadUsers);

// GET all users (Admin only)
adminRoute.get('/v1/admin', authorizeRoles('Admin'), getAllUsers);

// POST create a new user (Admin only)
adminRoute.post('/v1/admin', authorizeRoles('Admin'), createUser);

// GET a selected users info (Admin only)
adminRoute.get('/v1/admin/:userID', authorizeRoles('Admin'), getUserInfo);

// PATCH update any user (Admin only)
adminRoute.put('/v1/admin/:userID', authorizeRoles('Admin'), updateUser);

// DELETE a user (Admin only)
adminRoute.delete('/v1/admin/:userID', authorizeRoles('Admin'), deleteUser);

export default adminRoute;