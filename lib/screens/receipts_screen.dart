import 'package:flutter/material.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<Map<String, String>> _receipts = [
    {'title': 'Salário', 'value': 'R\$ 5.000,00'},
    {'title': 'Rendimentos', 'value': 'R\$ 20,00'},
  ];

  void _addReceipt(String title, String value) {
    setState(() {
      _receipts.add({'title': title, 'value': value});
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A8782);

    return Scaffold(
      appBar: AppBar(title: const Text('Receitas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'R\$ ${(_receipts.fold<num>(0, (sum, item) => sum + (double.tryParse(item['value']!.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.')) ?? 0))).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Receitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            ..._receipts.map((item) => _buildReceiptItem(item['title']!, item['value']!)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddReceiptScreen(onAdd: _addReceipt),
          ));
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildReceiptItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class AddReceiptScreen extends StatefulWidget {
  final Function(String, String) onAdd;
  const AddReceiptScreen({super.key, required this.onAdd});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Receita')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(labelText: 'Valor'),
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                widget.onAdd(_titleController.text, _valueController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}