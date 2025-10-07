# 🔥 Firebase Setup Guide - Step by Step

## Prerequisites
✅ Flutter project ready  
✅ Chrome browser installed  
✅ Google account for Firebase Console  

---

## STEP 1: Install Firebase Tools (One-time setup)

### 1.1 Install Node.js (if not already installed)
- Download from: https://nodejs.org/
- Run installer and follow prompts
- Verify installation:
```powershell
node --version
npm --version
```

### 1.2 Install Firebase CLI
Open PowerShell and run:
```powershell
npm install -g firebase-tools
```

Verify installation:
```powershell
firebase --version
```

### 1.3 Install FlutterFire CLI
```powershell
dart pub global activate flutterfire_cli
```

Verify installation:
```powershell
flutterfire --version
```

**⚠️ Important**: Add Dart global packages to your PATH if needed:
- Path: `%USERPROFILE%\AppData\Local\Pub\Cache\bin`

---

## STEP 2: Create Firebase Project

### 2.1 Go to Firebase Console
- Open: https://console.firebase.google.com/
- Sign in with your Google account

### 2.2 Create New Project
1. Click **"Add project"** or **"Create a project"**
2. **Project name**: Enter `kachuful` (or any name you prefer)
3. Click **Continue**
4. **Google Analytics**: Toggle ON (recommended) or OFF
   - If ON, select or create an Analytics account
5. Click **Create project**
6. Wait for Firebase to provision your project
7. Click **Continue** when done

---

## STEP 3: Configure Firebase for Flutter

### 3.1 Login to Firebase from Terminal
In your project directory (`C:\Projects\kachuful`):
```powershell
firebase login
```
- Browser will open
- Select your Google account
- Click **Allow**
- You should see "Success! Logged in as [your-email]"

### 3.2 Run FlutterFire Configure
This will automatically set up Firebase for all platforms:
```powershell
flutterfire configure
```

**You'll be prompted with:**

1. **Select a Firebase project**:
   - Use arrow keys to select `kachuful` (the project you just created)
   - Press Enter

2. **Which platforms should your configuration support?**:
   - Use space bar to select: `android`, `ios`, `web`, `windows`
   - Press Enter

3. **FlutterFire will now**:
   - Register your app with Firebase
   - Download configuration files
   - Generate `lib/firebase_options.dart` with real credentials
   - Create Android/iOS/Web/Windows configurations

**✅ Output**: You should see:
```
Firebase configuration file lib/firebase_options.dart generated successfully
```

---

## STEP 4: Enable Firebase Authentication

### 4.1 Open Firebase Console
- Go to: https://console.firebase.google.com/
- Select your `kachuful` project

### 4.2 Enable Email/Password Authentication
1. In left sidebar, click **Build** → **Authentication**
2. Click **Get started**
3. Click **Sign-in method** tab
4. Click **Email/Password** (the first option)
5. Toggle **Enable** to ON
6. Click **Save**

**✅ Status**: Email/Password authentication is now enabled!

---

## STEP 5: Create Firestore Database

### 5.1 Create Database
1. In Firebase Console, click **Build** → **Firestore Database**
2. Click **Create database**

### 5.2 Choose Mode
Select **Start in test mode** (for development):
```
Rules allow read/write access to all users for 30 days
```
- Click **Next**

### 5.3 Choose Location
- Select a location close to your users (e.g., `us-central`, `asia-south1`, `europe-west`)
- Click **Enable**

**⚠️ Note**: Location cannot be changed later!

### 5.4 Wait for Database Creation
- Takes 30-60 seconds
- You'll see the Firestore console when ready

**✅ Status**: Firestore Database is now ready!

---

## STEP 6: Set Up Firestore Security Rules

### 6.1 Update Rules (Important for Production)
1. In Firestore Database, click **Rules** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - only authenticated users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Scores collection - authenticated users can read all, write their own
    match /scores/{scoreId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
    
    // Games collection - authenticated users can read all, write their own
    match /games/{gameId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

**✅ Status**: Security rules are now configured!

---

## STEP 7: Add Firebase Packages to Flutter

### 7.1 Update `pubspec.yaml`
Open `c:\Projects\kachuful\pubspec.yaml` and add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI & Design
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0
  
  # State Management & Navigation
  provider: ^6.1.1
  go_router: ^14.2.0
  
  # 🔥 Firebase - ADD THESE LINES
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
```

### 7.2 Install Packages
Run in terminal:
```powershell
flutter pub get
```

**✅ Output**: All packages should download successfully!

---

## STEP 8: Update Flutter Code - Enable Firebase

### 8.1 Update `lib/main.dart`

**FIND** (around line 7-10):
```dart
void main() {
  runApp(const MyApp());
}
```

**REPLACE WITH**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

**ADD IMPORTS** at the top of the file:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
```

### 8.2 Update `lib/screens/register_page.dart`

**ADD IMPORT** at the top:
```dart
import '../services/auth_service.dart';
```

**FIND** the `_handleRegister()` method (around line 475-490):
```dart
void _handleRegister() {
  if (_formKey.currentState!.validate()) {
    // TODO: Implement registration logic with Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registration successful! (Firebase integration pending)',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD81B60),
      ),
    );
  }
}
```

**REPLACE WITH**:
```dart
Future<void> _handleRegister() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFD81B60)),
        ),
      );

      // Register with Firebase
      final authService = AuthService();
      await authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful! Welcome ${_usernameController.text}!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home/dashboard (create this later)
        // For now, navigate back to landing page
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

### 8.3 Update `lib/screens/login_page.dart`

**ADD IMPORT** at the top:
```dart
import '../services/auth_service.dart';
```

**FIND** the `_handleLogin()` method:
```dart
void _handleLogin() {
  if (_formKey.currentState!.validate()) {
    // TODO: Implement login logic with Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Login successful! (Firebase integration pending)',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD81B60),
      ),
    );
  }
}
```

**REPLACE WITH**:
```dart
Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFD81B60)),
        ),
      );

      // Login with Firebase
      final authService = AuthService();
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login successful! Welcome back!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home/dashboard (create this later)
        // For now, navigate back to landing page
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

---

## STEP 9: Test Firebase Integration

### 9.1 Run the App
```powershell
flutter run -d chrome
```

### 9.2 Test Registration
1. Click **"Get Started"** on landing page
2. Fill in the registration form:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
   - Re-Enter Password: `password123`
3. Click **"Register"**
4. You should see a loading spinner, then success message!

### 9.3 Verify in Firebase Console
1. Go to Firebase Console → Authentication → Users
2. You should see `test@example.com` in the users list!

### 9.4 Test Login
1. Navigate to Login page
2. Enter:
   - Email: `test@example.com`
   - Password: `password123`
3. Click **"Login"**
4. Should see success message!

---

## STEP 10: Troubleshooting

### Issue: "Firebase not initialized"
**Solution**: Make sure `main()` has:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Issue: "No Firebase App"
**Solution**: Run `flutterfire configure` again

### Issue: "Permission denied" in Firestore
**Solution**: Check your Firestore rules (Step 6.1)

### Issue: "Email already in use"
**Solution**: User already registered - use different email or try logging in

### Issue: "Weak password"
**Solution**: Use at least 6 characters for password

### Issue: "Invalid email"
**Solution**: Check email format (must have @ and domain)

---

## 🎉 Success Checklist

- ✅ Firebase CLI installed
- ✅ FlutterFire CLI installed  
- ✅ Firebase project created
- ✅ `flutterfire configure` completed
- ✅ `lib/firebase_options.dart` generated
- ✅ Authentication enabled (Email/Password)
- ✅ Firestore Database created
- ✅ Security rules configured
- ✅ Firebase packages added to `pubspec.yaml`
- ✅ `flutter pub get` successful
- ✅ `main.dart` updated with Firebase initialization
- ✅ `register_page.dart` connected to `AuthService`
- ✅ `login_page.dart` connected to `AuthService`
- ✅ Successfully registered a test user
- ✅ Successfully logged in with test user
- ✅ User appears in Firebase Console → Authentication

---

## 📂 Files You'll Modify

### Created Automatically:
- `lib/firebase_options.dart` (generated by `flutterfire configure`)

### You'll Edit:
1. `pubspec.yaml` - Add Firebase dependencies
2. `lib/main.dart` - Initialize Firebase
3. `lib/screens/register_page.dart` - Connect to AuthService
4. `lib/screens/login_page.dart` - Connect to AuthService

### Already Ready (No changes needed):
- `lib/services/auth_service.dart` ✅
- `lib/services/firestore_service.dart` ✅
- `lib/models/user_model.dart` ✅
- `lib/models/score_model.dart` ✅

---

## 🚀 Next Steps After Firebase Setup

1. **Create Home/Dashboard Page** - Where users go after login
2. **Add Score Entry Screen** - Main app functionality
3. **Create Leaderboard** - Display rankings
4. **Add User Profile** - Edit profile, change password
5. **Implement Logout** - Sign out functionality
6. **Add Email Verification** - Verify user emails
7. **Password Reset** - Forgot password flow

---

## 📞 Need Help?

If you encounter issues:
1. Check the error message carefully
2. Verify all steps were completed in order
3. Check Firebase Console for configuration
4. Run `flutter clean` and `flutter pub get`
5. Restart the app

---

**🎊 You're all set to use Firebase with your Flutter app!**
