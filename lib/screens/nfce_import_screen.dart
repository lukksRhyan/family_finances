import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/finance_state.dart';
import '../services/nfce_service.dart';

class NfceImportScreen extends StatefulWidget {
  final List<NoteProduct> items;
  const NfceImportScreen({super.key, required this.items});

  @override
  State<NfceImportScreen> createState() => _NfceImportScreenState();
}

class _NfceImportScreenState extends State<NfceImportScreen> {
  // Categoria padrão para os itens importados. O utilizador poderá alterar depois.
  final ExpenseCategory _defaultCategory = const ExpenseCategory(name: 'Compras', icon: Icons.shopping_cart);

  void _importItems() {
    final financeState = Provider.of<FinanceState>(context, listen: false);
    for (var item in widget.items) {
      final newExpense = Expense(
        title: item.name,
        value: item.totalPrice,
        category: _defaultCategory,
        note: 'Importado via NFC-e (Qtd: ${item.quantity}, Vl. Unit: ${item.unitPrice})',
        date: DateTime.now(),
        isRecurrent: false,
        isInInstallments: false,
      );
      financeState.addExpense(newExpense);
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.items.length} despesas importadas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Itens da Nota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _importItems,
            tooltip: 'Importar Todos',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('Qtd: ${item.quantity} | Vl. Unit: R\$ ${item.unitPrice.toStringAsFixed(2)}'),
            trailing: Text(
              'R\$ ${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
