import 'package:family_finances/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/shopping_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    final state = Provider.of<FinanceState>(context, listen: false);

    final data = {
      'expenses': state.expenses.map((e) => {
        'title': e.title,
        'value': e.value,
        'category': e.category.name,
        'note': e.note,
        'date': e.date.toIso8601String(),
      }).toList(),
      'receipts': state.receipts.map((r) => {
        'title': r.title,
        'value': r.value,
        'date': r.date.toIso8601String(),
      }).toList(),
      'shoppingList': state.shoppingList.map((item) => {
        'name': item.name,
        'isChecked': item.isChecked,
        'options': item.options.map((opt) => {
          'brand': opt.brand,
          'store': opt.store,
          'price': opt.price,
          'quantity': opt.quantity,
        }).toList(),
      }).toList(),
    };

    final jsonStr = jsonEncode(data);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/family_finances_export.json');
    await file.writeAsString(jsonStr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dados exportados para ${file.path}')),
    );
  }

  Future<void> _importData(BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/family_finances_export.json');
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo de importação não encontrado')),
      );
      return;
    }
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr);

    final state = Provider.of<FinanceState>(context, listen: false);

    // Limpa os dados atuais
    state.expenses.clear();
    state.receipts.clear();
    state.shoppingList.clear();

    // Importa despesas
    for (var e in data['expenses']) {
      state.addExpense(Expense(
        title: e['title'],
        value: e['value'],
        category: ExpenseCategory(name: e['category'], icon: Icons.category),
        note: e['note'],
        date: DateTime.parse(e['date']),
        isRecurrent: e['isRecurrent'] ?? false,
        isInInstallments: e['isInInstallments'] ?? false,
        installmentCount: e['installmentCount'],
      ));
    }

    // Importa receitas
    for (var r in data['receipts']) {
      state.addReceipt(Receipt(
        title: r['title'],
        value: r['value'],
        date: DateTime.parse(r['date']),
      ));
    }

    // Importa lista de compras
    for (var item in data['shoppingList']) {
      state.addShoppingItem(ShoppingItem(
        name: item['name'],
        isChecked: item['isChecked'],
        options: (item['options'] as List).map((opt) => ShoppingItemOption(
          brand: opt['brand'],
          store: opt['store'],
          price: opt['price'],
          quantity: opt['quantity'],
        )).toList(),
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados importados com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Exportar dados para JSON'),
              onPressed: () => _exportData(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Importar dados do JSON'),
              onPressed: () => _importData(context),
            ),
            const Spacer(),
            const Center(child: Text('Configurações do aplicativo')),
          ],
        ),
      ),
    );
  }
}