import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../styles/app_colors.dart';

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
    
    // Pega os produtos se for despesa
    final items = isExpense ? expenseToShow!.items : [];

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('Detalhes da Transação'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(categoryIcon, size: 40, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(DateFormat('dd/MM/yyyy - HH:mm').format(date), style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 30),
            
            // --- LISTA DE PRODUTOS (Se houver) ---
            if (items.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Itens da Nota (${items.length})", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final p = items[i];
                    final price = p.options.isNotEmpty ? p.options.first.price : 0.0;
                    return ListTile(
                      dense: true,
                      title: Text(p.name, style: const TextStyle(fontSize: 14)),
                      trailing: Text("R\$ ${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],

            // NOTA
            if (note != null && note.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("Observação", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(note),
              ),
            ]
          ],
        ),
      ),
    );
  }
}