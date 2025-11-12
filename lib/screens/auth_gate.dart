import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa o Provider
import '../models/finance_state.dart'; // Importa o FinanceState
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Ouve o stream de autenticação do Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // Se o estado de autenticação ainda está a ser determinado
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostra um ecrã de carregamento simples
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se o snapshot tem um utilizador (logado)
        if (snapshot.hasData) {
          // O FinanceState (que é inicializado no main.dart)
          // irá detetar esta mudança de utilizador e carregar os dados da nuvem.
          return const MainScreen();
        }

        // Se não há dados (utilizador deslogado)
        // Mostra o ecrã de login, que agora terá a opção "Continuar sem login"
        return const LoginScreen();
      },
    );
  }
}