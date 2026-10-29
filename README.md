# F.Ed Human Movement Sciences - Teaching and Learning (HMS-TnL) 📚

A comprehensive human movement sciences system built with Flutter (frontend) and Node.js (backend) designed for educational purposes and human movement sciences research and learning.

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Project Structure](#project-structure)
3. [Prerequisites](#prerequisites)
4. [Quick Start Guide](#quick-start-guide)
5. [Backend Setup](#backend-setup)
6. [Frontend Setup](#frontend-setup)
7. [Database Management](#database-management)
8. [Development Guide](#development-guide)
9. [API Documentation](#api-documentation)
10. [Troubleshooting](#troubleshooting)
11. [Contributing](#contributing)

## 🎯 Project Overview

The F.Ed HMS-TnL is a full-stack application that provides:

- **User Authentication & Authorization** - Secure login system with role-based access
- **Module Management** - Educational content organization and delivery for human movement sciences
- **Assignment System** - Assignment creation, submission, and grading for movement science courses
- **Feedback Management** - Comprehensive feedback collection and analysis for student assessments
- **Notification System** - Real-time notifications and alerts for course updates
- **Admin Dashboard** - Administrative controls and system monitoring for educational institutions
- **Cross-platform Support** - Mobile (iOS/Android), Web, and Desktop compatibility for accessibility

## 📁 Project Structure

```
F.Ed-HMS-TnL/
├── README.md                          # Main project documentation
└── Code/                             # Main application code
    ├── README.md                     # Detailed setup instructions
    ├── pubspec.yaml                  # Flutter dependencies
    ├── docker-compose.yml            # Docker configuration
    │
    ├── lib/                          # Flutter application source
    │   ├── main.dart                 # App entry point
    │   ├── auth/                     # Authentication logic
    │   ├── components/               # Reusable UI components
    │   ├── pages/                    # App screens/pages
    │   ├── flutter_flow/             # FlutterFlow generated code
    │   └── backend/                  # API integration layer
    │
    ├── backend/                      # Node.js API server
    │   ├── index.js                  # Server entry point
    │   ├── package.json              # Node.js dependencies
    │   ├── db.js                     # Database connection
    │   ├── controllers/              # Business logic handlers
    │   │   ├── authController.js     # Authentication logic
    │   │   ├── userController.js     # User management
    │   │   ├── moduleController.js   # Module operations
    │   │   ├── assignmentController.js
    │   │   ├── submissionController.js
    │   │   ├── feedbackController.js
    │   │   ├── notificationController.js
    │   │   ├── adminController.js
    │   │   └── userModuleController.js
    │   ├── routes/                   # API route definitions
    │   │   ├── authRouter.js
    │   │   ├── userRouter.js
    │   │   ├── moduleRouter.js
    │   │   ├── assignmentRouter.js
    │   │   ├── submissionRouter.js
    │   │   ├── feedbackRouter.js
    │   │   ├── notificationRouter.js
    │   │   ├── adminRouter.js
    │   │   └── userModuleRouter.js
    │   ├── middleware/               # Custom middleware
    │   ├── logs/                     # Application logs
    │   └── uploads/                  # File upload storage
    │
    ├── dump/                         # Database schema/migration files
    │   ├── nwu_hms_users.sql
    │   ├── nwu_hms_module.sql
    │   ├── nwu_hms_assignment.sql
    │   ├── nwu_hms_submission.sql
    │   ├── nwu_hms_feedback.sql
    │   ├── nwu_hms_notification.sql
    │   └── nwu_hms_user_module.sql
    │
    ├── assets/                       # Flutter assets
    │   ├── images/
    │   ├── fonts/
    │   ├── audios/
    │   └── videos/
    │
    ├── android/                      # Android platform files
    ├── ios/                          # iOS platform files
    ├── web/                          # Web platform files
    ├── linux/                        # Linux platform files
    ├── macos/                        # macOS platform files
    └── windows/                      # Windows platform files
```

## 🔧 Prerequisites

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.14+, or Linux
- **Git**: Latest version
- **Docker Desktop**: For containerized deployment
- **Node.js**: 18+ (if running backend locally)
- **Flutter SDK**: 3.0+
- **MySQL**: 8.0+ (if not using Docker)

### Development Tools (Recommended)

- **IDE**: Visual Studio Code with Flutter/Dart extensions
- **Database Management**: MySQL Workbench or similar
- **API Testing**: Postman or similar
- **Version Control**: Git

## 🚀 Quick Start Guide

### 1. Clone the Repository

```bash
git clone https://github.com/NWU-Enterprises-Pty-Ltd/F.Ed-HMS-TnL.git
cd F.Ed-HMS-TnL/Code
```

⚠️ **Important**: Ensure the folder path contains **no special characters or spaces**.

### 2. Start the Backend (Docker - Recommended)

```bash
# Navigate to the Code directory
cd Code

# Start services with Docker Compose
docker-compose up -d
```

This will start:

- MySQL database on port 3306
- Node.js API server on port 3000

### 3. Initialize Database

```bash
# Import database schema (one-time setup)
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_users.sql
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_module.sql
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_assignment.sql
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_submission.sql
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_feedback.sql
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_notification.sql
docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/nwu_hms_user_module.sql
```

### 4. Start the Flutter Frontend

```bash
# Get Flutter dependencies
flutter pub get

# Run on your preferred platform
flutter run                          # Shows available devices
flutter run -d chrome                # Web
flutter run -d android               # Android emulator
flutter run -d ios                   # iOS simulator (macOS only)
```

## 🔙 Backend Setup

### Option 1: Docker Deployment (Recommended)

1. **Configure Environment Variables**

   ```bash
   # The docker-compose.yml already includes default values:
   # MYSQL_HOST=mysql
   # MYSQL_DATABASE=nwu_hms
   # MYSQL_USER=admin
   # MYSQL_PASSWORD=hms
   # MYSQL_PORT=3306
   ```

2. **Start Services**

   ```bash
   docker-compose up -d
   ```

3. **Verify Backend is Running**
   ```bash
   curl http://localhost:3000/health
   ```

### Option 2: Local Development

1. **Install Dependencies**

   ```bash
   cd backend
   npm install
   ```

2. **Setup MySQL Database**

   - Install MySQL Server 8.0+
   - Create database: `CREATE DATABASE nwu_hms;`
   - Create user with appropriate permissions

3. **Configure Environment Variables**

   ```bash
   # Create .env file in backend directory
   MYSQL_HOST=localhost
   MYSQL_DATABASE=nwu_hms
   MYSQL_USER=your_username
   MYSQL_PASSWORD=your_password
   MYSQL_PORT=3306
   PORT=3000
   ```

4. **Import Database Schema**

   ```bash
   mysql -u your_username -p nwu_hms < ../dump/nwu_hms_users.sql
   # Repeat for all SQL files in dump/
   ```

5. **Start Development Server**
   ```bash
   npm run dev          # Development with auto-reload
   # or
   npm start           # Production mode
   ```

## 📱 Frontend Setup

### Install Flutter

1. **Download Flutter SDK**

   - Visit [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Download for your operating system

2. **Add Flutter to PATH**

   ```bash
   # Add to your shell profile (.bashrc, .zshrc, etc.)
   export PATH="$PATH:/path/to/flutter/bin"
   ```

3. **Verify Installation**
   ```bash
   flutter doctor
   ```

### Configure API Endpoints

For mobile development, you need to update API URLs:

1. **Locate API Configuration**

   ```bash
   # Find the API calls file
   find lib -name "*api*" -type f
   ```

2. **Update API Base URL**

   ```dart
   // In lib/backend/api_calls.dart or similar
   // Replace localhost with your machine's IP for physical devices
   const String baseURL = "http://YOUR_IP_ADDRESS:3000/api";

   // For emulator, use:
   // Android: http://10.0.2.2:3000/api
   // iOS: http://localhost:3000/api
   ```

### Run Flutter Application

```bash
# Install dependencies
flutter pub get

# List available devices
flutter devices

# Run on specific platform
flutter run -d chrome                # Web browser
flutter run -d android               # Android device/emulator
flutter run -d ios                   # iOS device/simulator
flutter run -d macos                 # macOS desktop
flutter run -d windows               # Windows desktop
flutter run -d linux                 # Linux desktop
```

## 🗄️ Database Management

### Database Schema

The application uses MySQL with the following main tables:

- **`nwu_hms_users`** - User accounts and profiles (students, lecturers, admin)
- **`nwu_hms_module`** - Human movement sciences modules/courses
- **`nwu_hms_assignment`** - Assignment definitions for movement science topics
- **`nwu_hms_submission`** - Student assignment submissions and assessments
- **`nwu_hms_feedback`** - Feedback and evaluations for student performance
- **`nwu_hms_notification`** - System notifications for course updates
- **`nwu_hms_user_module`** - User-module relationships and enrollments

### Adding New Users (Manual)

1. **Direct Database Insert**

   ```sql
   INSERT INTO nwu_hms_users (username, email, password_hash, role, created_at)
   VALUES ('newuser', 'user@example.com', 'hashed_password', 'student', NOW());
   ```

2. **Via API Endpoint**
   ```bash
   curl -X POST http://localhost:3000/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "username": "newuser",
       "email": "user@example.com",
       "password": "securepassword",
       "role": "student"
     }'
   ```

### Database Migrations

To add new database changes:

1. **Create SQL Migration File**

   ```sql
   -- dump/migration_YYYYMMDD_description.sql
   ALTER TABLE nwu_hms_users ADD COLUMN phone_number VARCHAR(20);
   ```

2. **Apply Migration**

   ```bash
   # Using Docker
   docker exec -i mysql-container mysql -u admin -phms nwu_hms < dump/migration_YYYYMMDD_description.sql

   # Using local MySQL
   mysql -u username -p nwu_hms < dump/migration_YYYYMMDD_description.sql
   ```

## 💻 Development Guide

### Adding New API Endpoints

1. **Create Controller Function**

   ```javascript
   // backend/controllers/newFeatureController.js
   export const getNewFeature = async (req, res) => {
     try {
       // Business logic here
       res.json({ success: true, data: result });
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   };
   ```

2. **Define Routes**

   ```javascript
   // backend/routes/newFeatureRouter.js
   import express from "express";
   import { getNewFeature } from "../controllers/newFeatureController.js";

   const router = express.Router();
   router.get("/new-feature", getNewFeature);

   export default router;
   ```

3. **Register Route in Main App**

   ```javascript
   // backend/index.js
   import newFeatureRoute from "./routes/newFeatureRouter.js";

   app.use("/api/new-feature", newFeatureRoute);
   ```

### Adding New Flutter Pages

1. **Create Page Widget**

   ```dart
   // lib/pages/new_page.dart
   import 'package:flutter/material.dart';

   class NewPage extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('New Page')),
         body: Center(child: Text('New Feature Content')),
       );
     }
   }
   ```

2. **Add Route Configuration**
   ```dart
   // Update routing configuration in your app
   ```

### Project Coding Standards

- **Backend**: Use ES6+ JavaScript with async/await
- **Frontend**: Follow Flutter/Dart best practices
- **Database**: Use prepared statements for SQL queries
- **Security**: Implement proper authentication and input validation
- **Logging**: Use structured logging for debugging

## 📚 API Documentation

### Authentication Endpoints

- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout
- `GET /api/auth/profile` - Get user profile

### Module Management

- `GET /api/modules` - List all human movement sciences modules
- `POST /api/modules` - Create new movement science module
- `GET /api/modules/:id` - Get specific module details
- `PUT /api/modules/:id` - Update module content
- `DELETE /api/modules/:id` - Delete module

### Assignment System

- `GET /api/assignments` - List movement science assignments
- `POST /api/assignments` - Create new assignment
- `GET /api/assignments/:id` - Get assignment details
- `POST /api/submissions` - Submit assignment solution
- `GET /api/submissions/:id` - Get submission details and grading

### User Management

- `GET /api/users` - List users (lecturers, students, admin)
- `GET /api/users/:id` - Get user profile details
- `PUT /api/users/:id` - Update user information
- `DELETE /api/users/:id` - Delete user account

### Admin Features

- `GET /api/admin/stats` - System and course statistics
- `GET /api/admin/logs` - Application logs and activity
- `POST /api/admin/backup` - Database backup for course data

## 🔧 Troubleshooting

### Common Backend Issues

1. **Port Already in Use**

   ```bash
   # Kill process using port 3000
   lsof -ti:3000 | xargs kill -9
   ```

2. **Database Connection Failed**

   - Verify MySQL is running
   - Check credentials in docker-compose.yml or .env
   - Ensure database exists

3. **Docker Issues**
   ```bash
   # Reset Docker containers
   docker-compose down
   docker-compose up -d --force-recreate
   ```

### Common Frontend Issues

1. **Flutter Doctor Issues**

   ```bash
   flutter doctor --verbose
   # Follow specific recommendations
   ```

2. **API Connection Issues**

   - Verify backend is running on correct port
   - Check API URLs in Flutter code
   - For physical devices, use machine IP instead of localhost

3. **Platform-Specific Issues**

   ```bash
   # Clean Flutter build
   flutter clean
   flutter pub get

   # Reset iOS pods (macOS only)
   cd ios && pod install && cd ..
   ```

### Performance Issues

1. **Slow Database Queries**

   - Check database indices
   - Review query patterns in controllers
   - Monitor logs in `backend/logs/`

2. **Flutter Performance**

   ```bash
   # Run in profile mode for testing
   flutter run --profile

   # Build optimized release
   flutter build apk --release
   flutter build web --release
   ```

## 🤝 Contributing

### Development Workflow

1. **Fork & Clone**

   ```bash
   git clone https://github.com/your-username/F.Ed-HMS-TnL.git
   cd F.Ed-HMS-TnL
   ```

2. **Create Feature Branch**

   ```bash
   git checkout -b feature/new-feature-name
   ```

3. **Make Changes**

   - Follow coding standards
   - Add tests where applicable
   - Update documentation

4. **Test Changes**

   ```bash
   # Test backend
   cd backend && npm test

   # Test Flutter
   flutter test
   ```

5. **Submit Pull Request**
   - Provide clear description
   - Reference any related issues
   - Ensure CI passes

### Code Review Guidelines

- **Backend Changes**: Ensure proper error handling and security
- **Frontend Changes**: Test on multiple platforms/screen sizes
- **Database Changes**: Include migration scripts
- **Documentation**: Update README if adding new features

## 📞 Support

For support and questions:

- **Issues**: Open GitHub issues for bugs and feature requests
- **Documentation**: Check `Code/README.md` for detailed setup instructions
- **Development**: Refer to inline code comments and API documentation

---

**Last Updated**: August 2025  
**Version**: 1.0.1  
**License**: MIT
