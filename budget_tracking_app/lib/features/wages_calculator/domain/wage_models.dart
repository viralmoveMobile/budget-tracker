enum WageMode { hourly, monthly }

class WageJob {
  final String id;
  final String? userId;
  final String name;
  final WageMode mode;
  final double baseAmount; // Hourly rate or Monthly salary
  final double overtimeRate;
  final double taxPercentage;
  final String? employer;
  final int profileType;

  WageJob({
    required this.id,
    this.userId,
    required this.name,
    required this.mode,
    required this.baseAmount,
    required this.overtimeRate,
    required this.taxPercentage,
    this.employer,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'mode': mode.name,
      'baseAmount': baseAmount,
      'overtimeRate': overtimeRate,
      'taxPercentage': taxPercentage,
      'employer': employer,
      'profileType': profileType,
    };
  }

  factory WageJob.fromMap(Map<String, dynamic> map) {
    return WageJob(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      mode: WageMode.values.firstWhere((e) => e.name == map['mode']),
      baseAmount: map['baseAmount'],
      overtimeRate: map['overtimeRate'],
      taxPercentage: map['taxPercentage'],
      employer: map['employer'],
      profileType: map['profileType'] ?? 0,
    );
  }

  WageJob copyWith({
    String? id,
    String? userId,
    String? name,
    WageMode? mode,
    double? baseAmount,
    double? overtimeRate,
    double? taxPercentage,
    String? employer,
    int? profileType,
  }) {
    return WageJob(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      baseAmount: baseAmount ?? this.baseAmount,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      employer: employer ?? this.employer,
      profileType: profileType ?? this.profileType,
    );
  }
}

class WorkEntry {
  final String id;
  final String? userId;
  final String jobId;
  final DateTime date;
  final double hours;
  final double overtimeHours;
  final String? notes;

  WorkEntry({
    required this.id,
    this.userId,
    required this.jobId,
    required this.date,
    required this.hours,
    required this.overtimeHours,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'jobId': jobId,
      'date': date.toIso8601String(),
      'hours': hours,
      'overtimeHours': overtimeHours,
      'notes': notes,
    };
  }

  factory WorkEntry.fromMap(Map<String, dynamic> map) {
    return WorkEntry(
      id: map['id'],
      userId: map['userId'],
      jobId: map['jobId'],
      date: DateTime.parse(map['date']),
      hours: map['hours'],
      overtimeHours: map['overtimeHours'],
      notes: map['notes'],
    );
  }

  WorkEntry copyWith({
    String? id,
    String? userId,
    String? jobId,
    DateTime? date,
    double? hours,
    double? overtimeHours,
    String? notes,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      notes: notes ?? this.notes,
    );
  }
}

class MonthlyWageSummary {
  final int month;
  final int year;
  final double totalHours;
  final double totalOvertimeHours;
  final double grossIncome;
  final double taxAmount;
  final double netPay;

  MonthlyWageSummary({
    required this.month,
    required this.year,
    required this.totalHours,
    required this.totalOvertimeHours,
    required this.grossIncome,
    required this.taxAmount,
    required this.netPay,
  });

  factory MonthlyWageSummary.calculate(
      WageJob job, List<WorkEntry> entries, int month, int year) {
    double totalHours = 0;
    double totalOvertimeHours = 0;

    for (var entry in entries) {
      if (entry.date.month == month && entry.date.year == year) {
        totalHours += entry.hours;
        totalOvertimeHours += entry.overtimeHours;
      }
    }

    double basePay = 0;
    if (job.mode == WageMode.hourly) {
      basePay = totalHours * job.baseAmount;
    } else {
      basePay = job.baseAmount;
    }

    double overtimePay = totalOvertimeHours * job.overtimeRate;
    double grossIncome = basePay + overtimePay;
    double taxAmount = (grossIncome * job.taxPercentage) / 100;
    double netPay = grossIncome - taxAmount;

    return MonthlyWageSummary(
      month: month,
      year: year,
      totalHours: totalHours,
      totalOvertimeHours: totalOvertimeHours,
      grossIncome: grossIncome,
      taxAmount: taxAmount,
      netPay: netPay,
    );
  }
}
