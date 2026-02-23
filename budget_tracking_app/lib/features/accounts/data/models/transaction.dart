enum TransactionType { income, expense, transfer }

class AccountTransaction {
  final String id;
  final String? userId;
  final String accountId;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? notes;
  final String? relatedTransactionId; // For transfers

  AccountTransaction({
    required this.id,
    this.userId,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
    this.relatedTransactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountId': accountId,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'relatedTransactionId': relatedTransactionId,
    };
  }

  factory AccountTransaction.fromMap(Map<String, dynamic> map) {
    return AccountTransaction(
      id: map['id'],
      userId: map['userId'],
      accountId: map['accountId'],
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      category: map['category'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      relatedTransactionId: map['relatedTransactionId'],
    );
  }

  AccountTransaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? notes,
    String? relatedTransactionId,
  }) {
    return AccountTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
    );
  }
}
