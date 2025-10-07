class AppConfig {
  // Firestore collection names (override with --dart-define at build/run time)
  static const String usersCollection =
      String.fromEnvironment('USERS_COLLECTION', defaultValue: 'users');
  static const String gamesCollection =
      String.fromEnvironment('GAMES_COLLECTION', defaultValue: 'games');

  // Feature flags
  static const bool requireEmailVerifiedToSave =
      bool.fromEnvironment('REQUIRE_EMAIL_VERIFIED', defaultValue: false);

  // Email action links
  // Optional: a clean URL where users land after verification/reset
  // Example: https://app.kachuful.com/verified
  static const String actionCodeUrl =
      String.fromEnvironment('ACTION_CODE_URL', defaultValue: '');
  // Optional: Firebase Dynamic Links domain for prettier links (e.g., kachu.page.link)
  static const String dynamicLinkDomain =
      String.fromEnvironment('DYNAMIC_LINK_DOMAIN', defaultValue: '');
}
