class CashAccount {
  final String id;
  final String? userId; // Added for multi-user isolation
  final String name;
  final String? description;
  final int profileType;

  CashAccount({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'profileType': profileType,
    };
  }

  factory CashAccount.fromMap(Map<String, dynamic> map) {
    return CashAccount(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      description: map['description'],
      profileType: map['profileType'] ?? 0,
    );
  }

  CashAccount copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? profileType,
  }) {
    return CashAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      profileType: profileType ?? this.profileType,
    );
  }
}
