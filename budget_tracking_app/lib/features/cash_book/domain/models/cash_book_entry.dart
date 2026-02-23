import 'package:budget_tracking_app/features/my_account/domain/models/user_profile.dart';

enum CashBookEntryType {
  inflow,
  outflow;
}

class CashBookEntry {
  final String id;
  final String? userId; // Added for multi-user isolation
  final double amount;
  final DateTime date;
  final String description;
  final CashBookEntryType type;
  final String category;
  final String? accountId;
  final ProfileType profileType;

  CashBookEntry({
    required this.id,
    this.userId,
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
    required this.category,
    this.accountId,
    this.profileType = ProfileType.personal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'type': type.name,
      'category': category,
      'accountId': accountId,
      'profileType': profileType.index,
    };
  }

  factory CashBookEntry.fromMap(Map<String, dynamic> map) {
    return CashBookEntry(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      type: CashBookEntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CashBookEntryType.outflow,
      ),
      category: map['category'],
      accountId: map['accountId'],
      profileType: map['profileType'] != null
          ? ProfileType.values[map['profileType']]
          : ProfileType.personal,
    );
  }

  CashBookEntry copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    String? description,
    CashBookEntryType? type,
    String? category,
    String? accountId,
    ProfileType? profileType,
  }) {
    return CashBookEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      profileType: profileType ?? this.profileType,
    );
  }
}
