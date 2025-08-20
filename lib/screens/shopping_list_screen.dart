import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<Map<String, dynamic>> _items = [
    {'name': 'Leite', 'price': 'R\$ 5,00', 'isChecked': false},
    {'name': 'Pão', 'price': 'R\$ 7,00', 'isChecked': true},
    {'name': 'Ovos', 'price': 'R\$ 12,00', 'isChecked': true},
  ];

  void _addItem(String name, String price) {
    setState(() {
      _items.add({'name': name, 'price': price, 'isChecked': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A8782);

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Compras')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Supermercado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._items.map((item) => _buildShoppingItem(item)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddShoppingItemScreen(onAdd: _addItem),
          ));
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildShoppingItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: item['isChecked'],
            onChanged: (bool? value) {
              setState(() {
                item['isChecked'] = value!;
              });
            },
            activeColor: const Color(0xFF2A8782),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 16))),
          Text(item['price'], style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class AddShoppingItemScreen extends StatefulWidget {
  final Function(String, String) onAdd;
  const AddShoppingItemScreen({super.key, required this.onAdd});

  @override
  State<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Preço'),
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                widget.onAdd(_nameController.text, _priceController.text);
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