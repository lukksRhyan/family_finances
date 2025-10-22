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


void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

