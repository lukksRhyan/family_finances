import 'dart:io';
import 'package:firebase_core/firebase_core.dart'; // 1. Adicionar import do Firebase Core
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'firebase_options.dart'; // 2. Adicionar import das opções geradas
import 'models/finance_state.dart';
import 'screens/auth_gate.dart';
import 'styles/app_theme.dart';

// 3. Transformar a função main em assíncrona
void main() async {
  // Garante que os bindings do Flutter estão prontos
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inicializa o Firebase com as opções da plataforma atual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lógica para o sqflite em desktop (pode ser mantida por segurança)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => FinanceState(),
      child: const FinancialManagerApp(),
    ),
  );
}

class FinancialManagerApp extends StatelessWidget {
  const FinancialManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador Financeiro',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.appTheme,
      // A aplicação agora começa no AuthGate
      home: const AuthGate(),
    );
  }
}

