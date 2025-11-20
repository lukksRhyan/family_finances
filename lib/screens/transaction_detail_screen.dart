import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/receipt.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Expense? expenseToShow;
  final Receipt? receiptToShow;
  const TransactionDetailScreen({super.key, this.expenseToShow, this.receiptToShow});

  @override
  Widget build(BuildContext context) {
    final isExpense = expenseToShow != null;
    final title = isExpense ? expenseToShow!.title : receiptToShow!.title;
    final value = isExpense ? expenseToShow!.value : receiptToShow!.value;
    final categoryIcon = isExpense ? expenseToShow!.category.icon : receiptToShow!.category.icon;
    final date = isExpense ? expenseToShow!.date : receiptToShow!.date;
    final note = isExpense ? expenseToShow!.note : receiptToShow!.note;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(categoryIcon, size: 40),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text('R\$ ${value.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(DateFormat('dd/MM/yyyy').format(date)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(child: Text(note ?? '')),
            )
          ],
        ),
      ),
    );
  }
}
