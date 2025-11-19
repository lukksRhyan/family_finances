import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import '../models/product.dart';
import 'add_product_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceState>(context);
    final products = finance.shoppingListProducts;

    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Compras")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          return Card(
            child: ListTile(
              leading: Checkbox(
                value: p.isChecked,
                onChanged: (v) => finance.toggleProductChecked(p, v!),
              ),
              title: Text(p.name),
              subtitle: Text(p.category.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => finance.deleteProduct(p.id ?? p.localId.toString()),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddProductScreen(product: p)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

