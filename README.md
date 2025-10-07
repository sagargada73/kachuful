# kachuful

Score Card Maintainer - A Flutter mobile app with Firebase backend for tracking game scores.

## Features

- 🎯 Track scores for multiple games
- 👥 User authentication
- 💾 Cloud storage with Firebase
- 📱 Beautiful Material Design UI
- 🔄 Real-time updates

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Firebase account
- Android Studio / Xcode for mobile development

### Setup Instructions

#### 1. Install Flutter Dependencies

```powershell
flutter pub get
```

#### 2. Set Up Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create a Firestore Database
4. Install Firebase CLI:

```powershell
npm install -g firebase-tools
```

5. Login to Firebase:

```powershell
firebase login
```

6. Install FlutterFire CLI:

```powershell
dart pub global activate flutterfire_cli
```

7. Configure Firebase for your Flutter app:

```powershell
flutterfire configure
```

This will:
- Select your Firebase project
- Generate `firebase_options.dart` with your config
- Set up Android and iOS Firebase configurations

#### 3. Firebase Security Rules

Set up Firestore security rules in Firebase Console:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /scores/{scoreId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    match /games/{gameId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null;
    }
  }
}
```

#### 4. Run the App

For Android:
```powershell
flutter run
```

For iOS (macOS only):
```powershell
flutter run -d ios
```

For web:
```powershell
flutter run -d chrome
```

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models
│   ├── user_model.dart
│   └── score_model.dart
├── screens/                     # UI screens
│   └── landing_page.dart
└── services/                    # Business logic
    ├── auth_service.dart        # Authentication
    └── firestore_service.dart   # Database operations
```

## Adding New Screens

To add a new screen:

1. Create a new file in `lib/screens/`
2. Import necessary packages
3. Create a StatelessWidget or StatefulWidget
4. Add navigation in the button's `onPressed` handler

Example:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => YourNewScreen()),
);
```

## Firebase Collections

### users
- `uid` (document ID)
- `email`: string
- `displayName`: string
- `photoUrl`: string (optional)
- `createdAt`: timestamp

### scores
- `id` (auto-generated)
- `userId`: string
- `gameId`: string
- `score`: number
- `playerName`: string
- `createdAt`: timestamp
- `metadata`: map (optional)

### games
- `id` (auto-generated)
- `name`: string
- `description`: string
- `createdAt`: timestamp

## Troubleshooting

### Firebase not initialized
Run `flutterfire configure` and restart the app.

### Build errors after adding dependencies
Run:
```powershell
flutter clean
flutter pub get
flutter run
```

### Android build issues
Ensure `minSdkVersion` in `android/app/build.gradle` is at least 21.

## Next Steps

1. Add authentication screens (login, register)
2. Create score entry screens
3. Build leaderboard views
4. Add user profile management
5. Implement game management

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## License

MIT License
