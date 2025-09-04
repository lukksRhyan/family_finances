import 'dart:convert';

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
      brand: map['brand'],
      store: map['store'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }
}

class ShoppingItem {
  final int? id;
  final String name;
  bool isChecked;
  final List<ShoppingItemOption> options;

  ShoppingItem({
    this.id,
    required this.name,
    this.isChecked = false,
    this.options = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_checked': isChecked ? 1 : 0,
      'options': jsonEncode(options.map((option) => option.toMap()).toList()),
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    final List<dynamic> optionsMap = jsonDecode(map['options']);
    final options = optionsMap.map((e) => ShoppingItemOption.fromMap(e)).toList();

    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      isChecked: map['is_checked'] == 1,
      options: options,
    );
  }
}