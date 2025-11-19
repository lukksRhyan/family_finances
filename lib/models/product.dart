import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_category.dart';
import 'product_option.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final ProductCategory category;
  final List<ProductOption> options;
  final bool isChecked;
  final int priority;
  final int? localId;

  String get nameLower => name.toLowerCase();

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.options,
    this.isChecked = false,
    this.priority = 3,
    this.localId,
  });

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    ProductCategory? category,
    List<ProductOption>? options,
    bool? isChecked,
    int? priority,
    int? localId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      options: options ?? this.options,
      isChecked: isChecked ?? this.isChecked,
      priority: priority ?? this.priority,
      localId: localId ?? this.localId,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'categoryId': categoryId,
      'options': options.map((e) => e.toMapForFirestore()).toList(),
      'isChecked': isChecked,
      'priority': priority,
    };
  }

  factory Product.fromMapFromFirestore(
    Map<String, dynamic> map,
    String id,
    ProductCategory category,
  ) {
    return Product(
      id: id,
      name: map['name'],
      categoryId: map['categoryId'],
      category: category,
      options: (map['options'] as List<dynamic>? ?? [])
          .map((e) => ProductOption.fromMapFromFirestore(e))
          .toList(),
      isChecked: map['isChecked'] ?? false,
      priority: map['priority'] ?? 3,
    );
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'optionsJson': ProductOption.encode(options),
      'isChecked': isChecked ? 1 : 0,
      'priority': priority,
    };
  }

  factory Product.fromMapForSqlite(
    Map<String, dynamic> map,
    ProductCategory category,
  ) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'],
      category: category,
      options: ProductOption.decode(map['optionsJson']),
      isChecked: map['isChecked'] == 1,
      priority: map['priority'] ?? 3,
      localId: map['localId'],
    );
  }
}
