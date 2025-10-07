Environment configuration (Flutter dart-define)

Firebase config keys for web are public by design. Instead of a .env file bundled into the app, use compile-time dart-defines to switch non-secret config like collection names and feature flags.

Available defines:
- --dart-define=USERS_COLLECTION=users
- --dart-define=GAMES_COLLECTION=games
- --dart-define=REQUIRE_EMAIL_VERIFIED=true

Examples:
flutter run -d chrome --dart-define=USERS_COLLECTION=users --dart-define=GAMES_COLLECTION=games --dart-define=REQUIRE_EMAIL_VERIFIED=true

Why not .env? On Flutter Web, anything bundled is visible to users. Keep sensitive data in Firebase Rules and project settings. Use separate Firebase projects for dev/prod.
