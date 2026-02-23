class Holiday {
  final String id;
  final String? userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;
  final String? notes;
  final int profileType;

  Holiday({
    required this.id,
    this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
    this.notes,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalBudget': totalBudget,
      'notes': notes,
      'profileType': profileType,
    };
  }

  factory Holiday.fromMap(Map<String, dynamic> map) {
    return Holiday(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalBudget: map['totalBudget'],
      notes: map['notes'],
      profileType: map['profileType'] ?? 0,
    );
  }

  Holiday copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? totalBudget,
    String? notes,
    int? profileType,
  }) {
    return Holiday(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalBudget: totalBudget ?? this.totalBudget,
      notes: notes ?? this.notes,
      profileType: profileType ?? this.profileType,
    );
  }
}
