import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import 'shopping_list_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeState = Provider.of<FinanceState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Visão Geral')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo total
            Text(
              'R\$ ${(financeState.totalReceitas - financeState.totalDespesas).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildBalanceSection(financeState),
            const SizedBox(height: 24),
            _buildSectionTitle('Despesas'),
            ...financeState.expenses.map((expense) => _buildExpenseRow(expense)),
            const Divider(height: 32),
            _buildSectionTitle('Receitas'),
            ...financeState.receipts.map((receipt) => _buildReceiptRow(receipt)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const ShoppingListScreen(),
          ));
        },
        backgroundColor: const Color(0xFF2A8782),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
        tooltip: 'Abrir lista de compras',
      ),
    );
  }

  Widget _buildBalanceSection(FinanceState financeState) {
    final totalReceitas = financeState.totalReceitas;
    final totalDespesas = financeState.totalDespesas;
    final receitasPercent = totalReceitas + totalDespesas == 0
        ? 0
        : (totalReceitas / (totalReceitas + totalDespesas)) * 100;
    final despesasPercent = totalReceitas + totalDespesas == 0
        ? 0
        : (totalDespesas / (totalReceitas + totalDespesas)) * 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('R\$ ${totalReceitas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 8),
            const Text('Despesas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('R\$ ${totalDespesas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.red)),
          ],
        ),
        SizedBox(
          height: 80,
          width: 80,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(color: Colors.green, value: receitasPercent.toDouble(), radius: 15, showTitle: false),
                PieChartSectionData(color: Colors.red, value: despesasPercent.toDouble(), radius: 15, showTitle: false),
              ],
              centerSpaceRadius: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildExpenseRow(Expense expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(expense.category.icon, color: Colors.red),
        title: Text(expense.title),
        subtitle: Text(expense.note),
        trailing: Text('R\$ ${expense.value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildReceiptRow(Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.green),
        title: Text(receipt.title),
        trailing: Text('R\$ ${receipt.value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
      ),
    );
  }
}