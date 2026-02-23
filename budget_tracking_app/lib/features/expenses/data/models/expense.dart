import 'package:budget_tracking_app/features/my_account/domain/models/user_profile.dart'; // Import ProfileType
import 'expense_category.dart';

class Expense {
  final String id;
  final String? userId; // Added for multi-user isolation
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
  final String? linkedAccount;
  final String currency;
  final bool isIncome;
  final ProfileType profileType; // Added for Personal/Business profile

  Expense({
    required this.id,
    this.userId,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.linkedAccount,
    this.currency = 'USD',
    this.isIncome = false,
    this.profileType = ProfileType.personal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'linkedAccount': linkedAccount,
      'currency': currency,
      'isIncome': isIncome ? 1 : 0,
      'profileType': profileType.index,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.others,
      ),
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      linkedAccount: map['linkedAccount'],
      currency: map['currency'] ?? 'USD',
      isIncome: (map['isIncome'] == 1 || map['isIncome'] == true),
      profileType: map['profileType'] != null
          ? ProfileType.values[map['profileType']]
          : ProfileType.personal,
    );
  }

  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? notes,
    String? linkedAccount,
    String? currency,
    bool? isIncome,
    ProfileType? profileType,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      linkedAccount: linkedAccount ?? this.linkedAccount,
      currency: currency ?? this.currency,
      isIncome: isIncome ?? this.isIncome,
      profileType: profileType ?? this.profileType,
    );
  }
}
