class ShoppingItemOption {
  final String brand;
  final String store;
  final double price;
  final String quantity;

  ShoppingItemOption({
    required this.brand,
    required this.store,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'store': store,
      'price': price,
      'quantity': quantity,
    };
  }

  factory ShoppingItemOption.fromMap(Map<String, dynamic> map) {
    return ShoppingItemOption(
      brand: map['brand'] ?? '',
      store: map['store'] ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      quantity: map['quantity'] ?? '',
    );
  }
}

class ShoppingItem {
  final String? id; // Alterado para String
  final String name;
  bool isChecked;
  final List<ShoppingItemOption> options;

  ShoppingItem({
    this.id,
    required this.name,
    this.isChecked = false,
    this.options = const [],
  });

  // toMap agora guarda as opções como uma lista de mapas
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isChecked': isChecked,
      'options': options.map((option) => option.toMap()).toList(),
    };
  }

  // fromMap agora lê a lista de mapas diretamente
  factory ShoppingItem.fromMap(Map<String, dynamic> map, {String? id}) {
    var optionsList = <ShoppingItemOption>[];
    if (map['options'] is List) {
      optionsList = (map['options'] as List)
          .map((e) => ShoppingItemOption.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return ShoppingItem(
      id: id,
      name: map['name'] ?? '',
      isChecked: map['isChecked'] ?? false,
      options: optionsList,
    );
  }
}
