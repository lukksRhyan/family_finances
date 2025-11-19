// lib/models/product.dart
import 'dart:convert';
import 'product_category.dart';
import 'product_option.dart';

class Product {
  final String? id;
  final int? localId;
  final String name;
  ProductCategory category;
  List<ProductOption> options;
  bool isChecked;
  int? priority;

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
      'categoryId': category.id,
      'options': options.map((o) => o.toMap()).toList(),
      'isChecked': isChecked,
      'priority': priority,
    };
  }

  Map<String, dynamic> toMapForSqlite() {
    // optionsJson stored as JSON string
    return {
      'id': id,
      'name': name,
      'categoryId': category.id,
      'optionsJson': jsonEncode(options.map((o) => o.toMap()).toList()),
      'isChecked': isChecked ? 1 : 0,
      'priority': priority,
    };
  }

  factory Product.fromMapFromFirestore(Map<String, dynamic> map, String id, ProductCategory category) {
    final rawOptions = map['options'];
    final List<ProductOption> parsed = [];
    if (rawOptions is List) {
      for (var o in rawOptions) {
        try {
          if (o is Map) {
            parsed.add(ProductOption.fromMap(Map<String, dynamic>.from(o)));
          } else if (o is Map<String, dynamic>) {
            parsed.add(ProductOption.fromMap(o));
          } else {
            // ignore malformed option
          }
        } catch (_) {
          // ignore this option (avoid calling undefined helper)
        }
      }
    }
    return Product(
      id: id,
      localId: null,
      name: map['name'] ?? '',
      category: category,
      options: parsed,
      isChecked: map['isChecked'] ?? false,
      priority: map['priority'] is int ? map['priority'] as int : (map['priority'] != null ? int.tryParse(map['priority'].toString()) : null),
    );
  }

  factory Product.fromMapForSqlite(Map<String, dynamic> map, ProductCategory category) {
    final localId = map['localId'] is int
        ? map['localId'] as int
        : (map['localId'] != null ? int.tryParse(map['localId'].toString()) : null);

    List<ProductOption> parsed = [];
    try {
      final optionsJson = map['optionsJson']?.toString();
      if (optionsJson != null && optionsJson.isNotEmpty) {
        final dynamic decoded = jsonDecode(optionsJson);
        if (decoded is List) {
          for (var o in decoded) {
            try {
              if (o is Map) {
                parsed.add(ProductOption.fromMap(Map<String, dynamic>.from(o)));
              }
            } catch (_) {
              // skip malformed option
            }
          }
        }
      }
    } catch (_) {
      // ignore parsing errors
    }

    return Product(
      id: map['id']?.toString(),
      localId: localId,
      name: map['name'] ?? '',
      category: category,
      options: parsed,
      isChecked: (map['isChecked'] ?? 0) == 1,
      priority: map['priority'] is int ? map['priority'] as int : (map['priority'] != null ? int.tryParse(map['priority'].toString()) : null),
    );
  }

  String get nameLower => name.trim().toLowerCase();
}
