import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'receipt_category.dart';

class Receipt {
  final String? id;
  final int? localId;
  final String title;
  final double value;
  final DateTime date;
  final bool isRecurrent;
  final int? recurrencyId;
  final ReceiptCategory category;
  final bool isShared; // NOVO: Flag para transação conjunta/compartilhada

  Receipt({
    this.id,
    this.localId,
    required this.title,
    required this.value,
    required this.date,
    required this.isRecurrent,
    this.recurrencyId,
    required this.category,
    this.isShared = false, // Padrão é falso
  });

  bool get isFuture => date.isAfter(DateTime.now());

  factory Receipt.fromMap(Map<String, dynamic> map, {String? id}) {
    return Receipt(
      id: id,
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      isRecurrent: map['is_recurrent'] ?? false,
      recurrencyId: map['recurrency_id'],
      category: ReceiptCategory(
        name: map['category_name'] ?? 'Outros',
        icon: IconData(
          map['category_icon'] ?? 0xe360,
          fontFamily: 'MaterialIcons',
        ),
      ),
      isShared: map['isShared'] ?? false, // NOVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      'date': Timestamp.fromDate(date),
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'is_recurrent': isRecurrent,
      'recurrency_id': recurrencyId,
      'isShared': isShared, // NOVO
    };
  }

  // Método para converter para Map (útil para Sqflite)
  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': localId, // Usa o localId para o Sqflite
      'title': title,
      'value': value,
      'date': date.toIso8601String(), // Armazena DateTime como String ISO
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'isRecurrent': isRecurrent ? 1 : 0, // SQLite não tem booleano, usa 0 ou 1
      'recurrencyId': recurrencyId,
       // isShared não é relevante para o DB local/privado
    };
  }

  // Método para converter de Map (útil para Sqflite)
  factory Receipt.fromMapForSqlite(Map<String, dynamic> map) {
    return Receipt(
      id: map['id']?.toString(), // O ID do Sqflite é int, mas o modelo usa String
      localId: map['id'] as int?,
      title: map['title'] as String,
      value: map['value'] as double,
      date: DateTime.parse(map['date'] as String), // Converte String ISO para DateTime
      isRecurrent: (map['isRecurrent'] as int) == 1,
      recurrencyId: map['recurrencyId'] as int?,
      category: ReceiptCategory(
        name: map['category_name'] as String,
        icon: IconData(
          map['category_icon'] as int,
          fontFamily: 'MaterialIcons',
        ),
      ),
      isShared: false, // Força falso no modo local
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      // O 'id' não é guardado aqui, ele é a chave do documento
      'title': title,
      'value': value,
      'date': Timestamp.fromDate(date), // Converte DateTime para Timestamp
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'isRecurrent': isRecurrent,
      'recurrency_id': recurrencyId,
      'isShared': isShared, // NOVO
    };
  }
  factory Receipt.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return Receipt(
      id: id, // Recebe o ID do documento
      title: map['title'],
      value: (map['value'] as num).toDouble(), // Converte 'num' para 'double'
      date: (map['date'] as Timestamp).toDate(), // Converte Timestamp para DateTime
      isRecurrent: map['isRecurrent'] ?? false,
      recurrencyId: map['recurrencyId'],
      category: ReceiptCategory(
        name: map['category_name'] ?? 'Outros',
        icon: IconData(
          map['category_icon'] ?? 0xe360, // Usa um ícone padrão se não encontrar
          fontFamily: 'MaterialIcons',
        ),
      ),
      isShared: map['isShared'] ?? false, // NOVO
    );
  }
  Receipt copyWith({
    String? id,
    int? localId,
    String? title,
    double? value,
    DateTime? date,
    bool? isRecurrent,
    int? recurrencyId,
    ReceiptCategory? category,
    bool? isShared, // NOVO
  }) {
    return Receipt(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      title: title ?? this.title,
      value: value ?? this.value,
      date: date ?? this.date,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      recurrencyId: recurrencyId ?? this.recurrencyId,
      category: category ?? this.category,
      isShared: isShared ?? this.isShared, // NOVO
    );
  }

}