import 'package:budget_tracking_app/features/my_account/domain/models/user_profile.dart'; // Import ProfileType
import 'expense_category.dart';

class BudgetLimit {
  final String id;
  final String? userId;
  final double amount;
  final ExpenseCategory? category; // null means overall monthly budget
  final int month; // 1-12
  final int year;
  final ProfileType profileType;

  BudgetLimit({
    required this.id,
    this.userId,
    required this.amount,
    this.category,
    required this.month,
    required this.year,
    this.profileType = ProfileType.personal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category?.name,
      'month': month,
      'year': year,
      'profileType': profileType.index,
    };
  }

  factory BudgetLimit.fromMap(Map<String, dynamic> map) {
    return BudgetLimit(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      category: map['category'] != null
          ? ExpenseCategory.values.firstWhere((e) => e.name == map['category'])
          : null,
      month: map['month'],
      year: map['year'],
      profileType: map['profileType'] != null
          ? ProfileType.values[map['profileType']]
          : ProfileType.personal,
    );
  }

  BudgetLimit copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCategory? category,
    int? month,
    int? year,
    ProfileType? profileType,
  }) {
    return BudgetLimit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      month: month ?? this.month,
      year: year ?? this.year,
      profileType: profileType ?? this.profileType,
    );
  }
}
