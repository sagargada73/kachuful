# Firebase Setup Guide

## Quick Start

### 1. Install Required Tools

```powershell
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

### 2. Run the Setup Script

```powershell
# Make sure you're in the project directory
cd c:\Projects\kachuful

# Run the setup script
.\setup_firebase.ps1
```

Or follow the manual steps below.

---

## Manual Setup Steps

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `kachuful` (or your preferred name)
4. Disable Google Analytics (optional for development)
5. Click "Create project"

### Step 2: Login to Firebase CLI

```powershell
firebase login
```

This will open a browser window for authentication.

### Step 3: Configure FlutterFire

```powershell
flutterfire configure
```

This interactive tool will:
- Show you a list of your Firebase projects
- Let you select which project to use
- Ask which platforms to configure (select Android, iOS, Web)
- Generate `lib/firebase_options.dart` with your Firebase config
- Update Android and iOS configuration files

### Step 4: Enable Firebase Authentication

1. In Firebase Console, go to **Authentication**
2. Click **Get Started**
3. Go to **Sign-in method** tab
4. Enable **Email/Password** provider
5. Click **Save**

### Step 5: Create Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (for development)
4. Choose a location (closest to you)
5. Click **Enable**

### Step 6: Add Firestore Security Rules

In Firebase Console, go to **Firestore Database** → **Rules** tab and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Scores collection
    match /scores/{scoreId} {
      // Anyone authenticated can read scores
      allow read: if request.auth != null;
      // Anyone authenticated can create scores
      allow create: if request.auth != null;
      // Only the score owner can update/delete
      allow update, delete: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Games collection
    match /games/{gameId} {
      // Anyone authenticated can read games
      allow read: if request.auth != null;
      // Anyone authenticated can create/update/delete games
      allow create, update, delete: if request.auth != null;
    }
  }
}
```

Click **Publish** to save the rules.

### Step 7: (Optional) Enable Firebase Storage

If you want to store images (e.g., user profile pictures):

1. In Firebase Console, go to **Storage**
2. Click **Get Started**
3. Start in **test mode**
4. Click **Next** and **Done**

Add storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Testing the Setup

### Run the app:

```powershell
flutter run
```

For Android emulator:
```powershell
flutter run -d emulator-5554
```

For web:
```powershell
flutter run -d chrome
```

### Verify Firebase Connection

The app should launch without errors. Check the console output for:
- `[firebase_core] Initialized Firebase`
- No Firebase initialization errors

---

## Troubleshooting

### "Firebase not initialized"

**Solution:** Run `flutterfire configure` again to regenerate the configuration.

### "minSdkVersion too low"

**Solution:** Already set to 21 in `android/app/build.gradle`. If you still get this error, increase to 23.

### "Build failed" after adding Firebase

**Solution:**
```powershell
flutter clean
flutter pub get
flutter run
```

### "Firebase CLI command not found"

**Solution:** Ensure Node.js and npm are installed, then:
```powershell
npm install -g firebase-tools
```

### "FlutterFire command not found"

**Solution:**
```powershell
dart pub global activate flutterfire_cli

# Add to PATH if needed
$env:PATH += ";$env:LOCALAPPDATA\Pub\Cache\bin"
```

Make it permanent by adding to System Environment Variables:
1. Search "Environment Variables" in Windows
2. Edit "Path" in User variables
3. Add: `%LOCALAPPDATA%\Pub\Cache\bin`

---

## Firebase Console URLs

- **Console Home:** https://console.firebase.google.com/
- **Authentication:** https://console.firebase.google.com/project/YOUR_PROJECT_ID/authentication
- **Firestore:** https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore
- **Storage:** https://console.firebase.google.com/project/YOUR_PROJECT_ID/storage

---

## Firebase Collections Structure

### `users` collection
```json
{
  "uid": "auto-generated",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "createdAt": "Timestamp"
}
```

### `scores` collection
```json
{
  "id": "auto-generated",
  "userId": "user-uid",
  "gameId": "game-id",
  "score": 100,
  "playerName": "John Doe",
  "createdAt": "Timestamp",
  "metadata": {
    "level": 5,
    "duration": 120
  }
}
```

### `games` collection
```json
{
  "id": "auto-generated",
  "name": "Card Game",
  "description": "A fun card game",
  "createdAt": "Timestamp"
}
```

---

## Next Steps

1. ✅ Firebase is configured
2. ✅ Landing page is implemented
3. 🔲 Add authentication screens (login/register)
4. 🔲 Add more pages (you mentioned you'll provide more designs)
5. 🔲 Implement score tracking features
6. 🔲 Add user profile management

Ready to add your next page! Just share the design and I'll implement it.
