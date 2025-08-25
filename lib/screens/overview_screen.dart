import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
            // Saldo atual
            Text(
              'Saldo atual: R\$ ${(financeState.totalReceitasAtuais - financeState.totalDespesasAtuais).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBalanceSection(financeState),
            const SizedBox(height: 24),
            _buildSectionTitle('A Receber / A Pagar'),
            _buildFutureBalanceSection(financeState),
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
    final receitas = financeState.totalReceitasAtuais;
    final despesas = financeState.totalDespesasAtuais;
    final receitasPercent = receitas + despesas == 0 ? 0 : (receitas / (receitas + despesas)) * 100;
    final despesasPercent = receitas + despesas == 0 ? 0 : (despesas / (receitas + despesas)) * 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receitas atuais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('R\$ ${receitas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 8),
            const Text('Despesas atuais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('R\$ ${despesas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.red)),
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

  Widget _buildFutureBalanceSection(FinanceState financeState) {
    final aReceber = financeState.totalAReceber;
    final aPagar = financeState.totalAPagar;
    final total = aReceber + aPagar;
    final aReceberPercent = total == 0 ? 0 : (aReceber / total) * 100;
    final aPagarPercent = total == 0 ? 0 : (aPagar / total) * 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A Receber', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('R\$ ${aReceber.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 8),
            const Text('A Pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('R\$ ${aPagar.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.red)),
          ],
        ),
        SizedBox(
          height: 80,
          width: 80,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(color: Colors.green, value: aReceberPercent.toDouble(), radius: 15, showTitle: false),
                PieChartSectionData(color: Colors.red, value: aPagarPercent.toDouble(), radius: 15, showTitle: false),
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
        leading: Icon(expense.category.icon, color: expense.isFuture ? Colors.orange : Colors.red),
        title: Text(expense.title),
        subtitle: Text(expense.isFuture ? 'A pagar em ${DateFormat('dd/MM/yyyy').format(expense.date)}' : DateFormat('dd/MM/yyyy').format(expense.date)),
        trailing: Text('R\$ ${expense.value.toStringAsFixed(2)}', style: TextStyle(color: expense.isFuture ? Colors.orange : Colors.red)),
      ),
    );
  }

  Widget _buildReceiptRow(Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(Icons.attach_money, color: receipt.isFuture ? Colors.blue : Colors.green),
        title: Text(receipt.title),
        subtitle: Text(receipt.isFuture ? 'A receber em ${DateFormat('dd/MM/yyyy').format(receipt.date)}' : DateFormat('dd/MM/yyyy').format(receipt.date)),
        trailing: Text('R\$ ${receipt.value.toStringAsFixed(2)}', style: TextStyle(color: receipt.isFuture ? Colors.blue : Colors.green)),
      ),
    );
  }
}