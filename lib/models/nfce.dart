import 'package:cloud_firestore/cloud_firestore.dart';
import 'nfce_item_detail.dart';

class Nfce {
  final String? id; // ID do documento no Firestore

  final String nfceKey; // Chave de acesso de 44 dígitos
  final String storeName;
  final double totalValue;
  final Timestamp date; // Data de emissão da nota
  final String taxInfo;
  // Poderia armazenar os detalhes dos itens aqui também, se útil
  final List<NfceItemDetail> items; // Armazena uma cópia dos itens lidos

  Nfce({
    this.id,

    required this.nfceKey,
    required this.storeName,
    required this.totalValue,
    required this.date,
    required this.taxInfo,
    required this.items,
  });

  // Método para converter para Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {

      'nfceKey': nfceKey,
      'storeName': storeName,
      'totalValue': totalValue,
      'date': date,
      'taxInfo': taxInfo,
      'items': items.map((item) => item.toMap()).toList(), // Salva os itens
    };
  }

  // Método para converter de Map (útil para Firestore)
  factory Nfce.fromMap(Map<String, dynamic> map, String id) {
     var itemsList = <NfceItemDetail>[];
    if (map['items'] is List) {
      itemsList = (map['items'] as List)
          .map((e) => NfceItemDetail.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return Nfce(
      id: id,

      nfceKey: map['nfceKey'] ?? '',
      storeName: map['storeName'] ?? 'Loja Desconhecida',
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] ?? Timestamp.now(),
      taxInfo: map['taxInfo'] ?? '',
      items: itemsList,
    );
  }
}
