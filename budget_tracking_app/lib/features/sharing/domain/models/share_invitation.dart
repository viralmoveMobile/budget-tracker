import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired;

  String get label {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
      case InvitationStatus.expired:
        return 'Expired';
    }
  }
}

class ShareInvitation {
  final String id;
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final String recipientEmail;
  final InvitationStatus status;
  final List<String> sharedDataTypes; // e.g., ['expenses', 'budgets']
  final DateTime createdAt;
  final DateTime? expiresAt;

  ShareInvitation({
    required this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerName,
    required this.recipientEmail,
    required this.status,
    required this.sharedDataTypes,
    required this.createdAt,
    this.expiresAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'recipientEmail': recipientEmail,
      'status': status.name,
      'sharedDataTypes': sharedDataTypes,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  // Create from Firestore document
  factory ShareInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShareInvitation(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      ownerName: data['ownerName'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      sharedDataTypes: List<String>.from(data['sharedDataTypes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  ShareInvitation copyWith({
    String? id,
    String? ownerId,
    String? ownerEmail,
    String? ownerName,
    String? recipientEmail,
    InvitationStatus? status,
    List<String>? sharedDataTypes,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return ShareInvitation(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerName: ownerName ?? this.ownerName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      status: status ?? this.status,
      sharedDataTypes: sharedDataTypes ?? this.sharedDataTypes,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isPending => status == InvitationStatus.pending && !isExpired;
}
