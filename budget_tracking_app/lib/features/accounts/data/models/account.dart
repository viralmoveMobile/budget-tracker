import 'package:flutter/material.dart';

enum AccountType {
  personal,
  business,
  household,
  others;

  String get label {
    switch (this) {
      case AccountType.personal:
        return 'Personal';
      case AccountType.business:
        return 'Business';
      case AccountType.household:
        return 'Household';
      case AccountType.others:
        return 'Others';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.personal:
        return Icons.person_rounded;
      case AccountType.business:
        return Icons.business_center_rounded;
      case AccountType.household:
        return Icons.home_rounded;
      case AccountType.others:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AccountType.personal:
        return Colors.blue;
      case AccountType.business:
        return Colors.orange;
      case AccountType.household:
        return Colors.teal;
      case AccountType.others:
        return Colors.grey;
    }
  }
}

class Account {
  final String id;
  final String? userId;
  final String name;
  final AccountType type;
  final String? description;
  final int profileType;

  Account({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.description,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name,
      'description': description,
      'profileType': profileType,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      type: AccountType.values.firstWhere((e) => e.name == map['type']),
      description: map['description'],
      profileType: map['profileType'] ?? 0,
    );
  }

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    String? description,
    int? profileType,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      profileType: profileType ?? this.profileType,
    );
  }
}
