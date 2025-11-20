import 'package:family_finances/models/receipt_category.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/expense_category.dart';

class AddTransactionScreen extends StatefulWidget {
  final Expense? expenseToEdit;
  final Receipt? receiptToEdit;
  const AddTransactionScreen({super.key, this.expenseToEdit, this.receiptToEdit});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _title = TextEditingController();
  final _value = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _isExpense = true;
      _title.text = e.title;
      _value.text = e.value.toString();
      _date = e.date;
    }
    if (widget.receiptToEdit != null) {
      final r = widget.receiptToEdit!;
      _isExpense = false;
      _title.text = r.title;
      _value.text = r.value.toString();
      _date = r.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FinanceState>(context);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Despesa'),
                  selected: _isExpense,
                  onSelected: (_) => setState(() => _isExpense = true),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Receita'),
                  selected: !_isExpense,
                  onSelected: (_) => setState(() => _isExpense = false),
                ),
              ],
            ),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: _value, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _date,
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Text(DateFormat('dd/MM/yyyy').format(_date)),
            ),
            ElevatedButton(
              onPressed: () async {
                final t = _title.text.trim();
                final v = double.tryParse(_value.text) ?? 0;
                if (t.isEmpty || v <= 0) return;

                if (_isExpense) {
                  final e = Expense(
                    id: widget.expenseToEdit?.id,
                    title: t,
                    value: v,
                    category: ExpenseCategory(name: 'Geral', icon: Icons.label),
                    note: '',
                    date: _date,
                    isRecurrent: false,
                    isInInstallments: false,
                  );
                  widget.expenseToEdit == null
                      ? await state.addExpense(e)
                      : await state.updateExpense(e);
                } else {
                  final r = Receipt(
                    id: widget.receiptToEdit?.id,
                    title: t,
                    value: v,
                    category: ReceiptCategory(name: 'Geral', icon: Icons.label),
                    note: '',
                    date: _date,
                  
                  );
                  widget.receiptToEdit == null
                      ? await state.addReceipt(r)
                      : await state.updateReceipt(r);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}
