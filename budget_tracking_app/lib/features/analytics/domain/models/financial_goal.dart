enum GoalType {
  savings('Savings'),
  debtReduction('Debt Reduction');

  final String label;
  const GoalType(this.label);
}

class FinancialGoal {
  final String id;
  final String? userId; // Added for multi-user isolation
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final GoalType type;
  final int profileType;

  FinancialGoal({
    required this.id,
    this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.type,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'type': type.name,
      'profileType': profileType,
    };
  }

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      deadline: DateTime.parse(map['deadline']),
      type: GoalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GoalType.savings,
      ),
      profileType: map['profileType'] ?? 0,
    );
  }

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  bool get isCompleted => currentAmount >= targetAmount;

  FinancialGoal copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    GoalType? type,
    int? profileType,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      type: type ?? this.type,
      profileType: profileType ?? this.profileType,
    );
  }
}
