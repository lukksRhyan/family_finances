import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const FinancialManagerApp());
}

class FinancialManagerApp extends StatelessWidget {
  const FinancialManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2A8782),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A8782),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF2A8782),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Outros widgets para adicionar despesa
            _buildCategorySelector(context),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nova categoria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A8782),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showAddCategoryDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    // Implementação do seletor de categorias
    return Container();
  }

  void _showAddCategoryDialog(BuildContext context) {
    // Implementação do diálogo para adicionar nova categoria
  }
}