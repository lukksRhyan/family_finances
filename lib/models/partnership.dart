// lib/models/partnership.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Partnership {
  final String id;
  final String user1Id;
  final String user2Id;
  final String sharedCollectionId;

  Partnership({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.sharedCollectionId,
  });

  static String createId(String a, String b) =>
      (a.compareTo(b) < 0) ? '$a _ $b' : '$b _ $a';

  factory Partnership.fromMap(Map<String, dynamic> map, String id) {
    return Partnership(
      id: id,
      user1Id: map['user1Id'],
      user2Id: map['user2Id'],
      sharedCollectionId: map['sharedCollectionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'sharedCollectionId': sharedCollectionId,
      'createdAt': Timestamp.now(),
    };
  }
}

class PartnershipInvite {
  final String id;
  final String senderId;
  final String receiverId;
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
