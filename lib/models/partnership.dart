import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa a parceria entre dois usuários para compartilhamento de finanças.
class Partnership {
  /// ID da Parceria (geralmente uma concatenação ordenada dos UIDs).
  final String id;
  
  /// UID do primeiro parceiro.
  final String user1Id;
  
  /// UID do segundo parceiro.
  final String user2Id;
  
  /// ID da sub-coleção raiz onde as transações conjuntas serão salvas.
  final String sharedCollectionId;

  Partnership({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.sharedCollectionId,
  });

  /// Cria o ID da parceria a partir de dois UIDs, garantindo consistência.
  static String createId(String uidA, String uidB) {
    // Ordena os UIDs para criar um ID de parceria canônico.
    return (uidA.compareTo(uidB) < 0) ? '${uidA}_$uidB' : '${uidB}_$uidA';
  }

  /// Construtor a partir de um Map do Firestore.
  factory Partnership.fromMap(Map<String, dynamic> map, String id) {
    return Partnership(
      id: id,
      user1Id: map['user1Id'],
      user2Id: map['user2Id'],
      sharedCollectionId: map['sharedCollectionId'],
    );
  }

  /// Converte para Map para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'sharedCollectionId': sharedCollectionId,
      'createdAt': Timestamp.now(), // Adiciona um timestamp de criação
    };
  }
}

/// Representa um convite de parceria
class PartnershipInvite {
  final String id;
  final String senderId;
  final String receiverId; // Usaremos o UID do recebedor
  final Timestamp sentAt;
  
  PartnershipInvite({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.sentAt,
  });

  factory PartnershipInvite.fromMap(Map<String, dynamic> map, String id) {
    return PartnershipInvite(
      id: id,
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      sentAt: map['sentAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'sentAt': sentAt,
    };
  }
}