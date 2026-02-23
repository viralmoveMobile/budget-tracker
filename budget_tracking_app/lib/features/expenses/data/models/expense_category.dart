import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  utilities,
  leisure,
  others;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.leisure:
        return 'Leisure';
      case ExpenseCategory.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_bus;
      case ExpenseCategory.utilities:
        return Icons.power;
      case ExpenseCategory.leisure:
        return Icons.sports_esports;
      case ExpenseCategory.others:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.utilities:
        return Colors.green;
      case ExpenseCategory.leisure:
        return Colors.purple;
      case ExpenseCategory.others:
        return Colors.grey;
    }
  }
}
