import 'package:flutter/material.dart';

enum HolidayExpenseCategory {
  travel(Icons.flight, Colors.blue, 'Travel'),
  accommodation(Icons.hotel, Colors.orange, 'Accommodation'),
  food(Icons.restaurant, Colors.green, 'Food'),
  activities(Icons.local_activity, Colors.purple, 'Activities'),
  shopping(Icons.shopping_bag, Colors.pink, 'Shopping');

  final IconData icon;
  final Color color;
  final String label;

  const HolidayExpenseCategory(this.icon, this.color, this.label);
}

class HolidayExpense {
  final String id;
  final String? userId;
  final String holidayId;
  final double amount; // Amount in Primary Currency
  final double? originalAmount; // Amount in foreign currency
  final String currency; // Original currency code
  final HolidayExpenseCategory category;
  final DateTime date;
  final String description;
  final String? receiptPath;

  HolidayExpense({
    required this.id,
    this.userId,
    required this.holidayId,
    required this.amount,
    this.originalAmount,
    this.currency = 'USD',
    required this.category,
    required this.date,
    required this.description,
    this.receiptPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'holidayId': holidayId,
      'amount': amount,
      'originalAmount': originalAmount,
      'currency': currency,
      'category': category.name,
      'date': date.toIso8601String(),
      'description': description,
      'receiptPath': receiptPath,
    };
  }

  factory HolidayExpense.fromMap(Map<String, dynamic> map) {
    return HolidayExpense(
      id: map['id'],
      userId: map['userId'],
      holidayId: map['holidayId'],
      amount: (map['amount'] as num).toDouble(),
      originalAmount: map['originalAmount'] != null
          ? (map['originalAmount'] as num).toDouble()
          : null,
      currency: map['currency'] ?? 'USD',
      category: HolidayExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => HolidayExpenseCategory.food,
      ),
      date: DateTime.parse(map['date']),
      description: map['description'],
      receiptPath: map['receiptPath'],
    );
  }

  HolidayExpense copyWith({
    String? id,
    String? userId,
    String? holidayId,
    double? amount,
    double? originalAmount,
    String? currency,
    HolidayExpenseCategory? category,
    DateTime? date,
    String? description,
    String? receiptPath,
  }) {
    return HolidayExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      holidayId: holidayId ?? this.holidayId,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }
}
