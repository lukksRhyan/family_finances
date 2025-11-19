import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import 'add_expense_screen.dart';
import 'add_receipt_screen.dart';
import 'nfce_reader_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceState>(context);
    final expenses = finance.expenses;
    final receipts = finance.receipts;

    final all = [...expenses, ...receipts];
    all.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visão Geral"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NfceReaderScreen()),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openAddMenu(context),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final item = all[i];

          final isExpense = item is Expense;
          final sign = isExpense ? "-" : "+";
          final color = isExpense ? Colors.red : Colors.green;

          return Card(
            child: ListTile(
              leading: Icon(
                isExpense ? Icons.remove_circle : Icons.attach_money,
                color: color,
              ),
              title: Text(item.title),
              subtitle: Text(item.date.toString().split(" ").first),
              trailing: Text("$sign${item.value.toStringAsFixed(2)}", style: TextStyle(color: color)),
              onTap: () {
                if (isExpense) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(expense: item),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddReceiptScreen(receipt: item),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _openAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle),
              title: const Text("Adicionar Despesa"),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Adicionar Receita"),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddReceiptScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
