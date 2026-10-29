# F.Ed Human Movement Sciences - Developer Setup Guide 🛠️

> **Note**: This is the detailed developer setup guide. For project overview and quick start, see the [main README](README.md).

## 📋 Table of Contents

1. [Developer Environment Setup](#developer-environment-setup)
   - [System Requirements](#system-requirements)
   - [Development Tools](#development-tools)
2. [Backend Development Setup](#backend-development-setup)
   - [Local Development Environment](#local-development-environment)
   - [Environment Configuration](#environment-configuration)
   - [Database Development Setup](#database-development-setup)
   - [API Testing Setup](#api-testing-setup)
3. [Frontend Development Setup](#frontend-development-setup)
   - [Flutter SDK Installation](#flutter-sdk-installation)
   - [IDE Configuration](#ide-configuration)
   - [Platform-Specific Setup](#platform-specific-setup)
   - [Device Configuration](#device-configuration)
4. [API Integration for Mobile Development](#api-integration-for-mobile-development)
   - [API Configuration](#api-configuration)
   - [Network Setup for Physical Devices](#network-setup-for-physical-devices)
   - [Testing API Endpoints](#testing-api-endpoints)
5. [Development Workflow](#development-workflow)
6. [Troubleshooting](#troubleshooting)
7. [Additional Resources](#additional-resources)

## 🔧 Developer Environment Setup

### System Requirements

**Minimum Requirements for Human Movement Sciences Development:**

- **OS**: Windows 10/11, macOS 10.14+, or Ubuntu 18.04+
- **RAM**: 8GB minimum (16GB recommended for smooth development)
- **Storage**: 10GB free space for development tools
- **Network**: Stable internet connection for package downloads

⚠️ **Important**: This application has been tested primarily on Windows 10/11 and macOS. Linux support is available but may require additional configuration.

### Development Tools

**Essential Tools:**

- 🐳 [Docker Desktop](https://www.docker.com/products/docker-desktop) - Container management
- 🌐 [Node.js 18+](https://nodejs.org/en/) - Backend runtime
- 🐦 [Flutter SDK 3.0+](https://flutter.dev/docs/get-started/install) - Frontend framework
- 🔧 [Git](https://git-scm.com/downloads) - Version control
- 💻 [Visual Studio Code](https://code.visualstudio.com/) - Primary IDE

**Recommended Tools:**

- 🛠️ [MySQL Workbench](https://dev.mysql.com/downloads/workbench/) - Database management
- 📮 [Postman](https://www.postman.com/downloads/) - API testing
- 🔍 [MongoDB Compass](https://www.mongodb.com/products/compass) - Database visualization (if using MongoDB)

**⚠️ Path Requirements**: When cloning the repository, ensure the folder path contains **no special characters or spaces** to avoid build issues.

## 🔙 Backend Development Setup

### Local Development Environment

For detailed backend development and debugging of the Human Movement Sciences API:

1. **Clone the Repository**

   ```bash
   git clone git@github.com:IncredibleZuess/ISE-Hms-Teaching-and-Learning.git
   cd ISE-Hms-Teaching-and-Learning
   ```

2. **Navigate to Backend Directory**

   ```bash
   cd backend
   ```

3. **Install Dependencies**
   ```bash
   npm install
   ```

### Environment Configuration

Create a comprehensive `.env` file in the `backend` directory for development:

```env
# Database Configuration
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=your_secure_password_here
MYSQL_DATABASE=nwu_hms
MYSQL_PORT=3306

# JWT Authentication
JWT_SECRET=your_super_secure_jwt_secret_key_for_hms
JWT_REFRESH_SECRET=your_super_secure_refresh_secret_key_for_hms

# JWT Token Expiration
JWT_ACCESS_EXPIRES=15m     # Access token (15 minutes for security)
JWT_REFRESH_EXPIRES=7d     # Refresh token (7 days)

# Application Configuration
PORT=3000
NODE_ENV=development

# Security & Rate Limiting
LOGIN_RATE_LIMIT_MAX=5          # Max login attempts per window
LOGIN_RATE_LIMIT_WINDOW=15      # Rate limit window in minutes
MAX_FILE_SIZE=52428800          # Max upload size (50MB)

# Email Service Configuration (for notifications)
EMAIL_SERVICE=gmail
EMAIL_USER=your_hms_system_email@gmail.com
EMAIL_PASS=your_gmail_app_password_here
# Note: Enable 2FA on Gmail and generate app-specific password

# File Storage (Backblaze B2 Configuration)
B2_BUCKET_ID=your_b2_bucket_id
B2_BUCKET_NAME=hms-file-storage
B2_REGION=us-west-002
B2_ENDPOINT=https://s3.us-west-002.backblazeb2.com
B2_ACCESS_KEY_ID=your_b2_access_key
B2_SECRET_ACCESS_KEY=your_b2_secret_key
B2_BUCKET_TYPE=allPrivate

# Development Logging
LOG_LEVEL=debug
LOG_FILE_PATH=./logs/hms-app.log
```

### Database Development Setup

**Local MySQL Setup for HMS Development:**

1. **Install MySQL Server 8.0+**

   ```bash
   # macOS (using Homebrew)
   brew install mysql
   brew services start mysql

   # Windows: Download from MySQL official site
   # Linux (Ubuntu/Debian)
   sudo apt update
   sudo apt install mysql-server
   ```

2. **Create HMS Database**

   ```sql
   CREATE DATABASE nwu_hms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'hms_dev'@'localhost' IDENTIFIED BY 'secure_dev_password';
   GRANT ALL PRIVILEGES ON nwu_hms.* TO 'hms_dev'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **Import HMS Schema and Sample Data**

   ```bash
   # Import all HMS tables in correct order
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_users.sql
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_module.sql
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_assignment.sql
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_submission.sql
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_feedback.sql
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_notification.sql
   mysql -u hms_dev -p nwu_hms < ../dump/nwu_hms_user_module.sql
   ```

4. **Start Development Server**
   ```bash
   npm run dev    # Development server with auto-reload
   # or
   npm start      # Production mode
   ```

### API Testing Setup

**Using Postman for HMS API Testing:**

1. **Import Postman Collection** (if available)
2. **Set Environment Variables:**

   ```
   BASE_URL: http://localhost:3000
   API_URL: {{BASE_URL}}/api
   TOKEN: (will be set after login)
   ```

3. **Test Core HMS Endpoints:**

   ```bash
   # Health check
   GET {{API_URL}}/health

   # Authentication
   POST {{API_URL}}/auth/login
   POST {{API_URL}}/auth/register

   # Module management
   GET {{API_URL}}/modules
   POST {{API_URL}}/modules

   # Assignment system
   GET {{API_URL}}/assignments
   POST {{API_URL}}/assignments
   ```

## 📱 Frontend Development Setup

### Flutter SDK Installation

**Complete Flutter Setup for HMS Development:**

#### 1. Download and Install Flutter SDK

```bash
# macOS (using Homebrew - Recommended)
brew install --cask flutter

# Manual Installation (All Platforms)
# Download from: https://flutter.dev/docs/get-started/install
# Extract to desired location (e.g., C:\src\flutter on Windows)
```

#### 2. Environment Variables Configuration

**Windows:**

```cmd
# Add to System PATH
setx PATH "%PATH%;C:\src\flutter\bin"
```

**macOS/Linux:**

```bash
# Add to shell profile (.bashrc, .zshrc, etc.)
export PATH="$PATH:/usr/local/flutter/bin"
source ~/.zshrc  # or ~/.bashrc
```

#### 3. Verify Flutter Installation

```bash
flutter doctor -v  # Detailed health check
flutter --version  # Check Flutter version
```

### IDE Configuration

**Visual Studio Code Setup (Recommended):**

1. **Install Required Extensions:**

   ```
   - Flutter (by Dart Code)
   - Dart (automatically installed with Flutter)
   - Flutter Widget Snippets
   - Awesome Flutter Snippets
   - Flutter Tree
   ```

2. **Configure VS Code Settings:**
   ```json
   // settings.json
   {
     "dart.flutterSdkPath": "/path/to/flutter",
     "dart.debugExternalLibraries": false,
     "dart.debugSdkLibraries": false,
     "flutter.experimentalRefactors": true
   }
   ```

**Android Studio Setup (Alternative):**

1. Install Android Studio with Flutter/Dart plugins
2. Configure Flutter SDK path in settings
3. Set up Android Virtual Device (AVD) Manager

### Platform-Specific Setup

#### Android Development

1. **Install Android Studio & SDK:**

   ```bash
   # Download Android Studio from: https://developer.android.com/studio
   # During installation, ensure these are selected:
   # - Android SDK
   # - Android SDK Platform
   # - Android Virtual Device (AVD)
   ```

2. **Configure Environment Variables:**

   ```bash
   # Add to shell profile
   export ANDROID_HOME=$HOME/Android/Sdk  # Linux/macOS
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

   # Windows
   setx ANDROID_HOME "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
   ```

3. **Accept Android Licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

#### iOS Development (macOS Only)

1. **Install Xcode:**

   ```bash
   # Install from Mac App Store or Apple Developer Portal
   # Minimum version: Xcode 12.0+
   ```

2. **Install iOS Simulator:**

   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

3. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   pod setup
   ```

#### Web Development

1. **Install Chrome:**

   ```bash
   # Chrome is required for Flutter web development
   # Download from: https://www.google.com/chrome/
   ```

2. **Enable Web Support:**
   ```bash
   flutter config --enable-web
   ```

### Device Configuration

#### Physical Android Device Setup

1. **Enable Developer Options:**

   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Return to Settings > Developer Options
   - Enable "USB Debugging"

2. **Verify Device Connection:**
   ```bash
   adb devices  # Should show your device
   flutter devices  # Should list your connected device
   ```

#### Android Emulator Setup

1. **Create Virtual Device:**

   ```bash
   # Open Android Studio
   # Tools > AVD Manager > Create Virtual Device
   # Choose device definition (e.g., Pixel 4)
   # Download system image (API 30+ recommended)
   ```

2. **Launch Emulator:**
   ```bash
   flutter emulators  # List available emulators
   flutter emulators --launch <emulator_name>
   ```

#### iOS Simulator Setup (macOS)

```bash
# List available simulators
xcrun simctl list devices

# Open iOS Simulator
open -a Simulator

# Or use Flutter command
flutter emulators --launch apple_ios_simulator
```

## 🌐 API Integration for Mobile Development

### API Configuration

**Configure HMS API Endpoints for Different Environments:**

#### 1. Locate API Configuration Files

```bash
# Find API-related files in the Flutter project
find lib -name "*api*" -type f
find lib -name "*backend*" -type f

# Common locations:
# lib/backend/api_calls.dart
# lib/flutter_flow/custom_functions.dart
```

#### 2. Environment-Specific API URLs

**Development Configuration:**

```dart
// lib/backend/api_calls.dart
class APIConfig {
  // Base URL configuration for different environments
  static String getBaseUrl() {
    const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

    switch (environment) {
      case 'production':
        return 'https://your-production-api.com';
      case 'staging':
        return 'https://staging-api.com';
      case 'development':
      default:
        return _getLocalBaseUrl();
    }
  }

  static String _getLocalBaseUrl() {
    // For Android Emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    // For iOS Simulator & Web
    else if (Platform.isIOS || kIsWeb) {
      return 'http://localhost:3000';
    }
    // For physical devices (replace with your machine's IP)
    else {
      return 'http://192.168.1.100:3000'; // Update this IP
    }
  }
}
```

### Network Setup for Physical Devices

#### 1. Find Your Machine's IP Address

**Windows:**

```cmd
ipconfig
# Look for "IPv4 Address" under your active network adapter
```

**macOS/Linux:**

```bash
ifconfig
# Look for "inet" address (usually starts with 192.168.x.x or 10.x.x.x)

# Alternative on macOS
ipconfig getifaddr en0  # Wi-Fi
ipconfig getifaddr en1  # Ethernet
```

#### 2. Update API Configuration for Physical Devices

```dart
// Update lib/backend/api_calls.dart for HMS system
class UserGroup {
  static String getBaseUrl({String? token = ''}) {
    // Replace with your actual machine IP
    return 'http://YOUR_MACHINE_IP:3000';  // e.g., 'http://192.168.1.100:3000'
  }

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer [token]',
  };

  // HMS-specific API calls
  static GetUserCall getUserCall = GetUserCall();
  static UpdateUserCall updateUserCall = UpdateUserCall();
  static GetModulesCall getModulesCall = GetModulesCall();
  static GetAssignmentsCall getAssignmentsCall = GetAssignmentsCall();
  static SubmitAssignmentCall submitAssignmentCall = SubmitAssignmentCall();

  static final interceptors = [
    RefreshToken(),
  ];
}
```

## 🔄 Development Workflow

### Daily Development Process

1. **Start Development Environment:**

   ```bash
   # Terminal 1: Start backend
   cd backend
   npm run dev

   # Terminal 2: Start Flutter with hot reload
   cd ..
   flutter run -d chrome  # or your preferred device
   ```

2. **Making Changes:**

   - **Backend changes**: Server auto-restarts with nodemon
   - **Frontend changes**: Hot reload automatically applies changes
   - **Database changes**: Apply migrations manually

3. **Testing Workflow:**

   ```bash
   # Test backend endpoints
   npm test  # If tests are configured

   # Test Flutter app
   flutter test

   # Integration testing
   flutter drive --target=test_driver/app.dart
   ```

### Code Quality & Standards

1. **Backend (Node.js):**

   ```bash
   # Linting
   npm run lint

   # Code formatting
   npm run format

   # Security audit
   npm audit
   ```

2. **Frontend (Flutter):**

   ```bash
   # Analyze code
   flutter analyze

   # Format code
   dart format .

   # Check for outdated packages
   flutter pub outdated
   ```

## 🔧 Troubleshooting

### Backend Issues

1. **Port 3000 Already in Use:**

   ```bash
   # Find process using port 3000
   lsof -ti:3000

   # Kill the process
   kill -9 $(lsof -ti:3000)
   ```

2. **Database Connection Issues:**

   ```bash
   # Check if MySQL is running
   brew services list | grep mysql  # macOS
   systemctl status mysql           # Linux

   # Test database connection
   mysql -u root -p -e "SHOW DATABASES;"
   ```

3. **Environment Variables Not Loading:**

   ```bash
   # Check .env file exists and has correct format
   cat backend/.env

   # Verify environment loading in Node.js
   node -e "console.log(process.env.MYSQL_HOST)"
   ```

### Frontend Issues

1. **Flutter Doctor Issues:**

   ```bash
   # Detailed health check
   flutter doctor -v

   # Fix common issues
   flutter doctor --android-licenses
   flutter clean && flutter pub get
   ```

2. **API Connection Problems:**

   ```bash
   # Test API accessibility
   curl http://localhost:3000/api/health
   curl http://YOUR_IP:3000/api/health  # For physical devices

   # Check network connectivity
   ping YOUR_MACHINE_IP  # From mobile device
   ```

3. **Build Issues:**

   ```bash
   # Clean Flutter build
   flutter clean
   flutter pub get
   flutter pub upgrade

   # iOS specific (macOS)
   cd ios && pod install && cd ..

   # Android specific
   cd android && ./gradlew clean && cd ..
   ```

### Device-Specific Issues

1. **Android Emulator Slow Performance:**

   ```bash
   # Enable hardware acceleration
   # In Android Studio: AVD Manager > Advanced Settings > Hardware Acceleration

   # Increase RAM allocation
   # AVD Manager > Edit AVD > Advanced Settings > RAM: 4GB+
   ```

2. **iOS Simulator Issues:**

   ```bash
   # Reset iOS Simulator
   xcrun simctl erase all

   # Restart CoreSimulator service
   sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService
   ```

## 📚 Additional Resources

### Documentation Links

- **Flutter Development:**

  - [Flutter Documentation](https://flutter.dev/docs)
  - [Dart Language Tour](https://dart.dev/guides/language/language-tour)
  - [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)

- **Backend Development:**

  - [Node.js Documentation](https://nodejs.org/en/docs/)
  - [Express.js Guide](https://expressjs.com/en/guide/routing.html)
  - [MySQL Documentation](https://dev.mysql.com/doc/)

- **Development Tools:**
  - [Docker Documentation](https://docs.docker.com/get-started/)
  - [Visual Studio Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
  - [Postman Learning Center](https://learning.postman.com/)

### Community & Support

- **Flutter Community:**

  - [Flutter Discord](https://discord.gg/flutter)
  - [Flutter Reddit](https://www.reddit.com/r/FlutterDev/)
  - [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)

- **HMS Project Support:**
  - Open GitHub issues for bugs and feature requests
  - Check existing documentation in the main README
  - Review inline code comments for implementation details

### Performance Tips

1. **Backend Optimization:**

   - Use database connection pooling
   - Implement proper error handling and logging
   - Use middleware for authentication and validation
   - Monitor API response times

2. **Flutter Performance:**
   - Use `const` constructors where possible
   - Implement proper state management
   - Optimize image loading and caching
   - Use `ListView.builder()` for large lists

---

**Last Updated**: August 2025  
**Version**: 1.0.1  
**For**: Human Movement Sciences Teaching & Learning System
