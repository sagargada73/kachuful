# Firebase Setup Script for Windows PowerShell
# Run this script to set up Firebase for your Flutter app

Write-Host "=== Firebase Setup for Kachuful ===" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
$firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseInstalled) {
    Write-Host "Firebase CLI not found. Installing..." -ForegroundColor Red
    Write-Host "Run: npm install -g firebase-tools" -ForegroundColor Green
    exit 1
}

Write-Host "✓ Firebase CLI found" -ForegroundColor Green
Write-Host ""

# Check if FlutterFire CLI is installed
Write-Host "Checking FlutterFire CLI..." -ForegroundColor Yellow
$flutterfireInstalled = Get-Command flutterfire -ErrorAction SilentlyContinue
if (-not $flutterfireInstalled) {
    Write-Host "FlutterFire CLI not found. Installing..." -ForegroundColor Red
    dart pub global activate flutterfire_cli
}

Write-Host "✓ FlutterFire CLI found" -ForegroundColor Green
Write-Host ""

# Login to Firebase
Write-Host "Step 1: Login to Firebase" -ForegroundColor Cyan
Write-Host "Running: firebase login" -ForegroundColor Gray
firebase login

Write-Host ""
Write-Host "Step 2: Configure FlutterFire" -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor Gray
Write-Host "  - Let you select your Firebase project" -ForegroundColor Gray
Write-Host "  - Generate firebase_options.dart with your config" -ForegroundColor Gray
Write-Host "  - Set up Android and iOS Firebase configurations" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to continue..."

flutterfire configure

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. Enable Authentication (Email/Password)" -ForegroundColor White
Write-Host "3. Create a Firestore Database (Start in test mode)" -ForegroundColor White
Write-Host "4. Add the security rules from FIREBASE_SETUP.md" -ForegroundColor White
Write-Host "5. Run: flutter run" -ForegroundColor White
Write-Host ""
