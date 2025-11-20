import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'overview_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (!snap.hasData) return const LoginScreen();
        return const OverviewScreen();
      },
    );
  }
}
