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
      'expenses': state.expenses.map((e) => e.toMap()).toList(),
      'receipts': state.receipts.map((r) => r.toMap()).toList(),
      'shoppingList': state.shoppingList.map((item) => {
        'name': item.name,
        'isChecked': item.isChecked,
        'options': item.options.map((opt) => opt.toMap()).toList(),
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
    } else {
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

    // Importa despesas, verificando duplicatas
    for (var e in data['expenses']) {
      final newExpense = Expense.fromMap(e);
      if (!state.expenses.any((existing) => existing.title == newExpense.title && existing.value == newExpense.value && existing.date.isAtSameMomentAs(newExpense.date))) {
        state.addExpense(newExpense);
      }
    }

    // Importa receitas, verificando duplicatas
    for (var r in data['receipts']) {
      final newReceipt = Receipt.fromMap(r);
      if (!state.receipts.any((existing) => existing.title == newReceipt.title && existing.value == newReceipt.value && existing.date.isAtSameMomentAs(newReceipt.date))) {
        state.addReceipt(newReceipt);
      }
    }

    // Importa lista de compras, verificando duplicatas
    for (var item in data['shoppingList']) {
      final newShoppingItem = ShoppingItem.fromMap(item);
      if (!state.shoppingList.any((existing) => existing.name == newShoppingItem.name)) {
        state.addShoppingItem(newShoppingItem);
      }
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