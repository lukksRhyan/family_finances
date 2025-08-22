class ShoppingItemOption {
  final String brand;
  final String store;
  final double price;
  final String quantity; // Novo campo

  ShoppingItemOption({
    required this.brand,
    required this.store,
    required this.price,
    required this.quantity,
  });
}

class ShoppingItem {
  final String name;
  bool isChecked;
  final List<ShoppingItemOption> options;

  ShoppingItem({
    required this.name,
    this.isChecked = false,
    this.options = const [],
  });
}