import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import '../models/product.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FinanceState>(context);
    final products = state.shoppingListProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Compras')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Novo item',
              suffixIcon: Icon(Icons.add),
            ),
            onSubmitted: (value) async {
              if (value.trim().isEmpty) return;
              await state.addProduct(Product(
                id: null,
                name: value.trim(),
                category: state.productCategories.first,
                isChecked: false,
              ));
              _controller.clear();
            },
          ),
          const SizedBox(height: 16),
          ...products.map(
            (p) => ListTile(
              title: Text(p.name),
              leading: Checkbox(
                value: p.isChecked,
                onChanged: (v) => state.toggleProductChecked(p, v ?? false),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => state.deleteProduct(p.id ?? p.localId.toString()),
              ),
            ),
          )
        ],
      ),
    );
  }
}
