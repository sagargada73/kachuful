import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'game_setup_page.dart';
import 'verify_email_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD81B60),
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final isPasswordProvider =
              user.providerData.any((p) => p.providerId == 'password');
          final isVerified = user.emailVerified || !isPasswordProvider;
          return isVerified ? const GameSetupPage() : const VerifyEmailPage();
        }

        // User is NOT logged in
        return const LoginPage();
      },
    );
  }
}
