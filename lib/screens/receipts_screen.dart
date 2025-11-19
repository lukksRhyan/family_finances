import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:family_finances/models/receipt_category.dart';
import '../models/finance_state.dart';
import '../models/receipt.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now(); // NOVO

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A8782);
    final financeState = Provider.of<FinanceState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Receitas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'R\$ ${financeState.totalReceitas.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildTextField(label: 'Título', hint: 'Título da receita', controller: _titleController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Valor', hint: '0,00', controller: _valueController),
            const SizedBox(height: 16),
            _buildDatePicker(context), // NOVO
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _valueController.text.isNotEmpty) {
                  final receipt = Receipt(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text,
                    value: double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0,
                    date: _selectedDate,

                    isRecurrent: false,
                  );
                  Provider.of<FinanceState>(context, listen: false).addReceipt(receipt);
                  _titleController.clear();
                  _valueController.clear();
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receita salva!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Salvar', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            const Text('Receitas cadastradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: ListView(
                children: financeState.receipts
                    .map((item) => _buildReceiptItem(item.title, item.value.toStringAsFixed(2), item.date))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 20),
        const SizedBox(width: 8),
        Text('Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: const Text('Alterar'),
        ),
      ],
    );
  }

  Widget _buildReceiptItem(String title, String value, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16)),
              Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Text('R\$ $value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}