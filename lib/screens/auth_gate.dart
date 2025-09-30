import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se o snapshot ainda não tem dados, mostra um ecrã de carregamento
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Se o utilizador está autenticado, mostra o ecrã principal
        return const MainScreen();
      },
    );
  }
}
