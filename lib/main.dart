import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/finance_state.dart';
import 'screens/main_screen.dart';
import 'styles/app_theme.dart';
void main() {
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
      home: const MainScreen(),
    );
  }
}
