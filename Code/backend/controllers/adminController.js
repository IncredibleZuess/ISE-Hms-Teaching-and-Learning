import bcryptjs from 'bcryptjs';
import pool from '../db.js';
import { adminLogger } from '../middleware/logger.js'; // Import admin logger
import xlsx from 'xlsx';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import crypto from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// In-memory store for bulk upload preview sessions (key -> {userID, validRows})
const previewSessions = new Map();
const PREVIEW_SESSION_TTL_MS = 10 * 60 * 1000; // 10 minutes

// Scheduled cleanup of expired preview sessions
setInterval(() => {
  const now = Date.now();
  for (const [token, session] of previewSessions) {
    if (now - session.createdAt > PREVIEW_SESSION_TTL_MS) {
      previewSessions.delete(token);
    }
  }
}, 60 * 1000).unref?.();


// Get All Users
// Function to get all users with only userID and formatted username
export const getAllUsers = async (req, res) => {
  try {
    // Execute query to get the userID, username, firstName, and lastName
    const [rows] = await pool.execute('SELECT userID, username, firstName, lastName FROM users');

    // Map the result to include only userID and formatted username
    const users = rows.map(user => ({
      userID: user.userID,
      user: `${user.username} (${user.firstName} ${user.lastName})`, // Formatted as "username (firstName lastName)"
    }));

    // Return the list of users

    // Log success message for fetching users (information log)
    adminLogger.info('Fetched all users successfully');
    res.status(200).json({ users });
  } catch (error) {
    // Log error message when fetching users fails (error log)
    adminLogger.error(`Error fetching users: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};






// Get User Info by userID
export const getUserInfo = async (req, res) => {
  const { userID } = req.params;

  try {
    // Execute query to get detailed user info by userID, excluding the email
    const [rows] = await pool.execute(
      'SELECT firstName, lastName, phoneNum, userType FROM users WHERE userID = ?',
      [userID]
    );

    if (rows.length === 0) {
      // Log warning if the user is not found (warning log)
      adminLogger.warn(`User not found with userID: ${userID}`);
      return res.status(404).json({ message: 'User not found' });
    }

    const user = rows[0];

    
    
    // Log success message for fetching user info (information log)
    adminLogger.info(`Fetched user info for userID: ${userID}`);
    res.status(200).json({
      firstName: user.firstName,
      lastName: user.lastName,
      phoneNum: user.phoneNum,
      userType: user.userType,
    });
  } catch (error) {
    // Log error message when fetching user details fails (error log)
    adminLogger.error(`Error fetching user details for userID: ${userID}, ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};





// Creating a new user //

// Function to generate a random 6-digit username
const generateUsername = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Function to check if a username already exists
const isUsernameUnique = async (username) => {
  const [rows] = await pool.execute('SELECT COUNT(*) as count FROM users WHERE username = ?', [username]);
  return rows[0].count === 0;
};

// Function to create a user
export const createUser = async (req, res) => {
  const { firstName, lastName, studentNum, phoneNum, userType } = req.body; // Destructure the data from the request

  try {
    // Validate required fields
    if (!firstName || !lastName || !studentNum || !userType) {
       // Log warning if required fields are missing (warning log)
      adminLogger.warn('Missing required fields for creating user');
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Check unique Student Number
    if (await !isUsernameUnique(studentNum))
    {
      adminLogger.warn('Student number already exists');
      return res.status(400).json({ message: 'Student number already exists' });
    }

    // Generate email based on username
    const email = `${studentNum}@mynwu.ac.za`;
    const password = `${studentNum}@Nwu`; // Generate a default password based on the username

    // Hash the password
    const hashedPassword = await bcryptjs.hash(password, 10); // Hash password with bcryptjs

    // Insert the new user into the database
    await pool.execute(
      'INSERT INTO users (username, firstName, lastName, password, email, phoneNum, userType) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [studentNum, firstName, lastName, hashedPassword, email, phoneNum, userType]
    );

    // Log success message for user creation (information log)
    adminLogger.info(`User created successfully with username: ${studentNum}`);
    // Send success response
    res.status(201).json({ message: 'User created successfully'});
  } catch (error) {
    // Handle any errors and send failure response
    // Log error message when creating user fails (error log)
    adminLogger.error(`Error creating user: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};






// Update a user
export const updateUser = async (req, res) => {
  const { userID } = req.params; // Extract userID from the route
  const { firstName, lastName, phoneNum, userType } = req.body; // Extract fields from the request body

  // Validate that all required fields are provided
  if (!firstName || !lastName || !phoneNum || !userType) {
    // Log warning if required fields are missing (warning log)
    adminLogger.warn(`Missing required fields for updating user for: ${userID}`);
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    // Check if user exists
    const [existingUser] = await pool.execute(
      'SELECT * FROM users WHERE userID = ?',
      [userID]
    );

    if (existingUser.length === 0) {
      // Log warning if the user is not found (warning log)
      adminLogger.warn(`User not found with userID: ${userID}`);
      return res.status(404).json({ message: 'User not found' });
    }

    // Static update query
    await pool.execute(
      'UPDATE users SET firstName = ?, lastName = ?, phoneNum = ?, userType = ? WHERE userID = ?',
      [firstName, lastName, phoneNum, userType, userID]
    );

    // Log success message for user update (information log)
    adminLogger.info(`User updated successfully with userID: ${userID}`);
    res.status(200).json({ message: 'User updated successfully' });
  } catch (error) {
    // Log error message when updating user fails (error log)
    adminLogger.error(`Error updating user with userID: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};





// Delete a user
export const deleteUser = async (req, res) => {
  const { userID } = req.params;

  try {
    // Check if the user exists
    const [existingUser] = await pool.execute(
      'SELECT userID FROM users WHERE userID = ?',
      [userID]
    );


    if (existingUser.length === 0) {
      // Log warning if the user is not found (warning log)
      adminLogger.warn(`User not found with userID: ${userID}`);
      return res.status(404).json({ message: 'User not found' });
    }

    // Execute the delete query
    await pool.execute('DELETE FROM users WHERE userID = ?', [userID]);

    // Log success message for user deletion (information log)
    adminLogger.info(`User deleted successfully with userID: ${userID}`);
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    // Log error message when deleting user fails (error log)
    adminLogger.error(`Error deleting user with user: ${error.message}`, { error });
    res.status(500).json({ message: 'Internal server error' });
  }
};


// Bulk Upload Users from Excel
export const downloadBulkUploadTemplate = async (req, res) => {
  try {
    // Create template workbook
    const wb = xlsx.utils.book_new();

    // Template columns per Functional Spec FR-EU-03:
    // Student Number, First Name, Last Name, Email, Module Code
    const templateData = [
      ['Student Number', 'First Name', 'Last Name', 'Email', 'Module Code'],
      ['12345678', 'John', 'Doe', 'john.doe@example.com', 'HMS101']
    ];

    const ws = xlsx.utils.aoa_to_sheet(templateData);

    // Set column widths for better readability
    ws['!cols'] = [
      { wch: 16 }, // Student Number
      { wch: 18 }, // First Name
      { wch: 18 }, // Last Name
      { wch: 30 }, // Email
      { wch: 14 }, // Module Code
    ];

    xlsx.utils.book_append_sheet(wb, ws, 'Students');

    // Generate buffer
    const buffer = xlsx.write(wb, { type: 'buffer', bookType: 'xlsx' });

    // Set response headers
    res.setHeader('Content-Disposition', 'attachment; filename=bulk_upload_students_template.xlsx');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

    adminLogger.info('Bulk upload template downloaded');
    res.send(buffer);
  } catch (error) {
    adminLogger.error(`Error generating template: ${error.message}`, { error });
    res.status(500).json({ message: 'Error generating template' });
  }
};

// Validate email format
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// Validate phone number format (South African)
const isValidPhoneNumber = (phoneNum) => {
  const phoneRegex = /^0[0-9]{9}$/;
  return phoneRegex.test(phoneNum);
};

export const bulkUploadUsers = async (req, res) => {
  try {
    if (!req.file) {
      adminLogger.warn('No file uploaded for bulk user creation');
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Read the uploaded Excel file
    const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];

    // Convert to JSON, starting from row 3 (index 1 in the array after headers)
    // This skips the example row
    const allData = xlsx.utils.sheet_to_json(worksheet);

    // Skip the first row (example row - row B/2)
    const data = allData.slice(1);

    if (data.length === 0) {
      adminLogger.warn('Uploaded file contains no data (only example row found)');
      return res.status(400).json({ error: 'File contains no student data. Please add students starting from row 3.' });
    }

    const validationErrors = [];
    const usersToCreate = [];
    const userModuleMappings = [];
    const requiredFields = ['firstName', 'lastName', 'studentNum', 'email'];

    // Validate each row
    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      const rowNumber = i + 3; // +3 because: Excel is 1-indexed, row 1 is header, row 2 is example, data starts at row 3
      const errors = [];

      // Check for missing required fields
      for (const field of requiredFields) {
        if (!row[field] || row[field].toString().trim() === '') {
          errors.push(`Missing ${field}`);
        }
      }

      // Validate email format
      if (row.email && !isValidEmail(row.email.toString().trim())) {
        errors.push('Invalid email format');
      }

      // Validate phone number format (if provided)
      if (row.phoneNum && row.phoneNum.toString().trim() !== '' && !isValidPhoneNumber(row.phoneNum.toString().trim())) {
        errors.push('Invalid phone number format (must be 10 digits starting with 0)');
      }

      // Check if student number already exists
      if (row.studentNum) {
        const [existingUser] = await pool.execute(
          'SELECT username FROM users WHERE username = ?',
          [row.studentNum.toString().trim()]
        );
        if (existingUser.length > 0) {
          errors.push('Student number already exists');
        }
      }

      // Check if email already exists
      if (row.email) {
        const [existingEmail] = await pool.execute(
          'SELECT email FROM users WHERE email = ?',
          [row.email.toString().trim()]
        );
        if (existingEmail.length > 0) {
          errors.push('Email already exists');
        }
      }

      // Validate module code if provided
      if (row.moduleCode && row.moduleCode.toString().trim() !== '') {
        const [moduleExists] = await pool.execute(
          'SELECT moduleID FROM module WHERE moduleCode = ?',
          [row.moduleCode.toString().trim()]
        );
        if (moduleExists.length === 0) {
          errors.push(`Module code '${row.moduleCode.toString().trim()}' does not exist`);
        }
      }

      if (errors.length > 0) {
        validationErrors.push({
          row: rowNumber,
          message: errors.join(', ')
        });
      } else {
        const studentNum = row.studentNum.toString().trim();
        usersToCreate.push({
          firstName: row.firstName.toString().trim(),
          lastName: row.lastName.toString().trim(),
          studentNum: studentNum,
          email: row.email.toString().trim(),
          phoneNum: row.phoneNum && row.phoneNum.toString().trim() !== '' ? row.phoneNum.toString().trim() : null,
          password: `${studentNum}@Nwu`, // Auto-generated password
          userType: 'student' // All users are students
        });

        // Store module mapping if provided
        if (row.moduleCode && row.moduleCode.toString().trim() !== '') {
          userModuleMappings.push({
            studentNum: studentNum,
            moduleCode: row.moduleCode.toString().trim()
          });
        }
      }
    }

    // If there are validation errors, return them
    if (validationErrors.length > 0) {
      adminLogger.warn(`Bulk upload validation failed with ${validationErrors.length} errors`);
      return res.status(400).json({
        error: 'Validation failed',
        validationErrors
      });
    }

    // Create all users
    let successCount = 0;
    const creationErrors = [];
    const userIdMap = {}; // Map student numbers to userIDs

    for (const user of usersToCreate) {
      try {
        // Hash the password
        const hashedPassword = await bcryptjs.hash(user.password, 10);

        // Insert the user
        const [result] = await pool.execute(
          'INSERT INTO users (username, firstName, lastName, password, email, phoneNum, userType) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [user.studentNum, user.firstName, user.lastName, hashedPassword, user.email, user.phoneNum, user.userType]
        );

        userIdMap[user.studentNum] = result.insertId;
        successCount++;
      } catch (error) {
        creationErrors.push({
          studentNum: user.studentNum,
          error: error.message
        });
      }
    }

    // Add users to modules if specified
    let moduleAssignmentCount = 0;
    const moduleErrors = [];

    for (const mapping of userModuleMappings) {
      try {
        const userId = userIdMap[mapping.studentNum];
        if (!userId) {
          continue; // Skip if user creation failed
        }

        // Get module ID
        const [moduleResult] = await pool.execute(
          'SELECT moduleID FROM module WHERE moduleCode = ?',
          [mapping.moduleCode]
        );

        if (moduleResult.length > 0) {
          const moduleId = moduleResult[0].moduleID;

          // Check if mapping already exists
          const [existingMapping] = await pool.execute(
            'SELECT * FROM user_module WHERE userID = ? AND moduleID = ?',
            [userId, moduleId]
          );

          if (existingMapping.length === 0) {
            // Insert into user_module table
            await pool.execute(
              'INSERT INTO user_module (userID, moduleID) VALUES (?, ?)',
              [userId, moduleId]
            );
            moduleAssignmentCount++;
          }
        }
      } catch (error) {
        moduleErrors.push({
          studentNum: mapping.studentNum,
          moduleCode: mapping.moduleCode,
          error: error.message
        });
      }
    }

    adminLogger.info(`Bulk upload completed: ${successCount} users created, ${moduleAssignmentCount} module assignments`);

    let message = `${successCount} users created successfully`;
    if (moduleAssignmentCount > 0) {
      message += `, ${moduleAssignmentCount} assigned to modules`;
    }

    if (creationErrors.length > 0 || moduleErrors.length > 0) {
      return res.status(207).json({
        message: message + `, but ${creationErrors.length + moduleErrors.length} errors occurred`,
        successCount,
        moduleAssignmentCount,
        errors: [...creationErrors, ...moduleErrors]
      });
    }

    res.status(200).json({
      message,
      successCount,
      moduleAssignmentCount
    });

  } catch (error) {
    adminLogger.error(`Error during bulk user upload: ${error.message}`, { error });
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ---------------------------------------------------------------
// Phase 2: Preview/Confirm bulk upload flow (Functional Spec FR-EU-01..08)
// ---------------------------------------------------------------

// Normalise a row keyed by template headers into a canonical object.
// Supports both the new spec headers and the legacy lowercase headers.
const normaliseRow = (row) => {
  const get = (...keys) => {
    for (const k of keys) {
      if (row[k] != null && row[k] !== '') return row[k];
    }
    return undefined;
  };

  return {
    studentNum: get('Student Number', 'studentNum'),
    firstName: get('First Name', 'firstName'),
    lastName: get('Last Name', 'lastName'),
    email: get('Email', 'email'),
    moduleCode: get('Module Code', 'moduleCode'),
  };
};

// Validate a single row; returns array of error messages (empty = valid)
const validateUploadRow = async (row, seenNumbers, seenEmails) => {
  const errors = [];
  const required = ['studentNum', 'firstName', 'lastName', 'email'];

  for (const field of required) {
    if (row[field] == null || String(row[field]).trim() === '') {
      errors.push(`Missing ${field}`);
    }
  }

  if (row.studentNum) {
    const num = String(row.studentNum).trim();
    if (!/^\d{8,9}$/.test(num)) {
      errors.push('Student number must be 8-9 digits');
    } else if (seenNumbers.has(num)) {
      errors.push('Duplicate student number in file');
    } else {
      seenNumbers.add(num);
    }
  }

  if (row.email) {
    const email = String(row.email).trim();
    if (!isValidEmail(email)) {
      errors.push('Invalid email format');
    } else if (seenEmails.has(email)) {
      errors.push('Duplicate email in file');
    } else {
      seenEmails.add(email);
    }
  }

  // Uniqueness against the database / module existence is checked by the caller
  return errors;
};

// POST /v1/admin/bulk-upload/preview
// Upload a .xlsx file and return a preview payload (valid_rows, error_rows) without inserting.
export const bulkUploadPreview = async (req, res) => {
  try {
    if (!req.file) {
      adminLogger.warn('No file uploaded for bulk upload preview');
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const allData = xlsx.utils.sheet_to_json(worksheet, { defval: '' });

    const data = allData.map((row, i) => ({ rowNumber: i + 2, ...normaliseRow(row) }));

    if (data.length === 0) {
      adminLogger.warn('Uploaded file contains no data rows');
      return res.status(400).json({ error: 'File contains no student data rows.' });
    }

    const seenNumbers = new Set();
    const seenEmails = new Set();
    const validRows = [];
    const errorRows = [];

    // Library-level checks (format/duplicates in file)
    for (const row of data) {
      const errors = await validateUploadRow(row, seenNumbers, seenEmails);
      if (errors.length > 0) {
        errorRows.push({ row: row.rowNumber, studentNum: row.studentNum, errors });
      } else {
        validRows.push(row);
      }
    }

    // Database-level checks on valid rows: existing student number, existing email, module existence
    const dbCheckedValid = [];
    for (const row of validRows) {
      const dbErrors = [];
      const num = String(row.studentNum).trim();
      const email = String(row.email).trim();

      const [existingUser] = await pool.execute('SELECT userID, username, email FROM users WHERE username = ?', [num]);
      if (existingUser.length > 0) {
        dbErrors.push('Student number already exists');
      } else {
        const [existingEmail] = await pool.execute('SELECT email FROM users WHERE email = ?', [email]);
        if (existingEmail.length > 0) {
          dbErrors.push('Email already exists');
        }
      }

      let module = null;
      if (row.moduleCode && String(row.moduleCode).trim() !== '') {
        const [moduleRows] = await pool.execute('SELECT moduleID FROM module WHERE moduleCode = ?', [String(row.moduleCode).trim()]);
        if (moduleRows.length === 0) {
          dbErrors.push(`Module code '${String(row.moduleCode).trim()}' does not exist`);
        } else {
          module = { moduleID: moduleRows[0].moduleID };
        }
      }

      if (dbErrors.length > 0) {
        errorRows.push({ row: row.rowNumber, studentNum: row.studentNum, errors: dbErrors });
      } else {
        dbCheckedValid.push({ ...row, module });
      }
    }

    // Generate a session token to carry the validated rows to the confirm step
    const token = crypto.randomBytes(24).toString('hex');
    previewSessions.set(token, {
      userID: req.user.userID,
      createdAt: Date.now(),
      rows: dbCheckedValid,
    });

    adminLogger.info(`Bulk upload preview completed: ${dbCheckedValid.length} valid, ${errorRows.length} invalid rows`);
    res.status(200).json({
      sessionToken: token,
      validRows: dbCheckedValid.map((r) => ({
        row: r.rowNumber,
        studentNum: r.studentNum,
        firstName: r.firstName,
        lastName: r.lastName,
        email: r.email,
        moduleCode: r.moduleCode || null,
      })),
      errorRows,
    });
  } catch (error) {
    adminLogger.error(`Error during bulk upload preview: ${error.message}`, { error });
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /v1/admin/bulk-upload/confirm
// Confirm and execute the import using the preview session token.
export const bulkUploadConfirm = async (req, res) => {
  const { sessionToken, overwriteDuplicates } = req.body;

  try {
    if (!sessionToken) {
      return res.status(400).json({ error: 'sessionToken is required' });
    }

    const session = previewSessions.get(sessionToken);
    if (!session) {
      return res.status(400).json({ error: 'Preview session expired or not found. Please re-upload the file.' });
    }

    // Only the user who created the preview may confirm it
    if (session.userID !== req.user.userID) {
      return res.status(403).json({ error: 'Preview session does not belong to the current user' });
    }

    previewSessions.delete(sessionToken); // token is single-use

    const rows = session.rows;
    let createdCount = 0;
    let skippedCount = 0;
    const failed = [];

    for (const row of rows) {
      try {
        const hashedPassword = await bcryptjs.hash(`${String(row.studentNum).trim()}@Nwu`, 10);
        const [result] = await pool.execute(
          `INSERT INTO users (username, firstName, lastName, password, email, phoneNum, userType)
           VALUES (?, ?, ?, ?, ?, '', ?)`,
          [String(row.studentNum).trim(), row.firstName, row.lastName, hashedPassword,
           String(row.email).trim(), 'Student']
        );

        // Enrol into module if provided
        if (row.module) {
          const [existingMapping] = await pool.execute(
            'SELECT * FROM user_module WHERE userID = ? AND moduleID = ?',
            [result.insertId, row.module.moduleID]
          );
          if (existingMapping.length === 0) {
            await pool.execute('INSERT INTO user_module (userID, moduleID) VALUES (?, ?)', [result.insertId, row.module.moduleID]);
          }
        }

        createdCount++;
      } catch (error) {
        // Duplicate key during insert -> skip (or overwrite if requested)
        if (error.code === 'ER_DUP_ENTRY' && overwriteDuplicates) {
          const num = String(row.studentNum).trim();
          await pool.execute(
            `UPDATE users SET firstName = ?, lastName = ?, email = ? WHERE username = ?`,
            [row.firstName, row.lastName, String(row.email).trim(), num]
          );
          createdCount++;
        } else if (error.code === 'ER_DUP_ENTRY') {
          skippedCount++;
          failed.push({ row: row.rowNumber, studentNum: row.studentNum, reason: 'Duplicate student number skipped' });
        } else {
          failed.push({ row: row.rowNumber, studentNum: row.studentNum, reason: error.message });
        }
      }
    }

    const summary = {
      totalRows: rows.length,
      created: createdCount,
      skipped: skippedCount,
      failed: failed.length,
      failures: failed,
    };

    adminLogger.info(`Bulk upload confirm completed: ${JSON.stringify(summary)}`);
    res.status(200).json({ message: 'Import completed', summary });
  } catch (error) {
    adminLogger.error(`Error confirming bulk upload: ${error.message}`, { error });
    res.status(500).json({ error: 'Internal server error' });
  }
};