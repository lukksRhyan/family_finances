import 'package:family_finances/models/expense_category.dart';
import 'package:family_finances/models/receipt_category.dart';
import 'package:file_picker/file_picker.dart';
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
    File file;
    if (Platform.isWindows) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum arquivo selecionado')),
        );
        return;
       }

       final filePath = result.files.single.path!;
       file = File(filePath);
    }else{
      final directory = await getApplicationDocumentsDirectory();
      file = File('${directory.path}/family_finances_export.json');
    }


    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo de importação não encontrado')),
      );
      return;
    }
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr);

    final state = Provider.of<FinanceState>(context, listen: false);

   

    // Importa despesas
    for (var e in data['expenses']) {
      if (state.expenses.contains(e)) {
        continue; // Pula despesas já existentes
      }
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
    for (var importedReceipt in data['receipts']) {
      if(state.receipts.contains(importedReceipt)){
        continue; // Pula receitas já existentes
      }
        print("Receita já existe: ${importedReceipt['title']} - ${importedReceipt['value']}");
      state.addReceipt(Receipt(
        title: importedReceipt['title'],
        value: importedReceipt['value'],
        date: DateTime.parse(importedReceipt['date']),
        category: ReceiptCategory(name: 'Outros', icon: Icons.category),
        isRecurrent: importedReceipt['isRecurrent'] ?? false,
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