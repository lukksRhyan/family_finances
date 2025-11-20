import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finance_state.dart';
import 'auth_gate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FinanceState>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          //
          // Exibe e-mail logado
          //
          if (user != null)
            ListTile(
              title: Text(user.email ?? ''),
              subtitle: const Text('Conta logada'),
            ),

          //
          // Botão sair
          //
          if (user != null)
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                state.forceNotify();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (_) => false,
                );
              },
              child: const Text('Sair'),
            ),

          //
          // Botão login/criar conta
          //
          if (user == null)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                );
              },
              child: const Text('Login / Criar Conta'),
            ),

          const Divider(),

          //
          // Recarregar estado
          //
          ListTile(
            title: const Text("Recarregar dados"),
            subtitle: const Text("Forçar atualização do estado"),
            trailing: const Icon(Icons.refresh),
            onTap: () {
              state.forceNotify();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Estado atualizado')),
              );
            },
          ),
        ],
      ),
    );
  }
}
