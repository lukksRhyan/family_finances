// lib/models/product.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_category.dart';
import 'product_option.dart';

class Product {
  final String? id;
  final int? localId;
  final String name;
  final ProductCategory category;
  final List<ProductOption> options;
  final bool isChecked;
  final int? priority;

  String get nameLower => name.toLowerCase();
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;

  return other is Product &&
      nameLower == other.nameLower;
}
 
  Product({
    this.id,
    this.localId,
    required this.name,
    required this.category,
    this.options = const [],
    this.isChecked = false,
    this.priority,
  });

  Product copyWith({
    String? id,
    int? localId,
    String? name,
    ProductCategory? category,
    List<ProductOption>? options,
    bool? isChecked,
    int? priority,
  }) {
    return Product(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      name: name ?? this.name,
      category: category ?? this.category,
      options: options ?? List<ProductOption>.from(this.options),
      isChecked: isChecked ?? this.isChecked,
      priority: priority ?? this.priority,
    );
    }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'category': category.toMapForFirestore(),
      'options': options.map((o) => o.toMap()).toList(),
      'isChecked': isChecked,
      'priority': priority,
    };
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'name': name,
      'category': category.toMapForSqlite(),
      'optionsJson': ProductOption.encode(options),
      'isChecked': isChecked ? 1 : 0,
      'priority': priority,
    };
  }

  factory Product.fromMapFromFirestore(
      Map<String, dynamic> map,
      String id,
      ) {
    final List options = map['options'] ?? [];
    final parsed = options.map((o) => ProductOption.fromMap(o)).toList();

    return Product(
      id: id,
      name: map['name'] ?? '',
      category: ProductCategory.fromMapFromFirestore(map['category'], map['category']["id"] ?? "undefined"),
      options: List<ProductOption>.from(parsed),
      isChecked: map['isChecked'] ?? false,
      priority: map['priority'],
    );
  }

  factory Product.fromMapForSqlite(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString(),
      localId: map['localId'] is int ? map['localId'] : int.tryParse(map['localId'].toString()),
      name: map['name'],
      category: ProductCategory.fromMapForSqlite(map['category']),
      options: ProductOption.decode(map['optionsJson']),
      isChecked: map['isChecked'] == 1,
      priority: map['priority'],
    );
  }
  
  @override
  int get hashCode => name.hashCode;
  
}
