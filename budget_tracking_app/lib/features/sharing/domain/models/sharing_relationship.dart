import 'package:cloud_firestore/cloud_firestore.dart';

enum SharePermission {
  view,
  edit;

  String get label {
    switch (this) {
      case SharePermission.view:
        return 'View Only';
      case SharePermission.edit:
        return 'View & Edit';
    }
  }
}

class SharingRelationship {
  final String id;
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final String recipientId;
  final String recipientEmail;
  final List<String> dataTypes; // e.g., ['expenses', 'budgets']
  final SharePermission permission;
  final String status; // 'active', 'paused'
  final DateTime createdAt;

  SharingRelationship({
    required this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerName,
    required this.recipientId,
    required this.recipientEmail,
    required this.dataTypes,
    required this.permission,
    required this.status,
    required this.createdAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'dataTypes': dataTypes,
      'permission': permission.name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory SharingRelationship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharingRelationship(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      ownerName: data['ownerName'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      dataTypes: List<String>.from(data['dataTypes'] ?? []),
      permission: SharePermission.values.firstWhere(
        (e) => e.name == data['permission'],
        orElse: () => SharePermission.view,
      ),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  bool get isActive => status == 'active';
}
