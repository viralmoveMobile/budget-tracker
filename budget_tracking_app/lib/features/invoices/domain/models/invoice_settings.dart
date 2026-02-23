class InvoiceSettings {
  final String? userId; // Added for multi-user isolation
  final String companyName;
  final String companyAddress;
  final String companyEmail;
  final String companyPhone;
  final String? logoPath;
  final double defaultTaxRate;
  final double defaultHourlyRate;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? routingNumber;
  final int profileType;

  InvoiceSettings({
    this.userId,
    required this.companyName,
    required this.companyAddress,
    required this.companyEmail,
    required this.companyPhone,
    this.logoPath,
    this.defaultTaxRate = 0.0,
    this.defaultHourlyRate = 0.0,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.routingNumber,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'logoPath': logoPath,
      'defaultTaxRate': defaultTaxRate,
      'defaultHourlyRate': defaultHourlyRate,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'profileType': profileType,
    };
  }

  factory InvoiceSettings.fromMap(Map<String, dynamic> map) {
    return InvoiceSettings(
      userId: map['userId'],
      companyName: map['companyName'] ?? '',
      companyAddress: map['companyAddress'] ?? '',
      companyEmail: map['companyEmail'] ?? '',
      companyPhone: map['companyPhone'] ?? '',
      logoPath: map['logoPath'],
      defaultTaxRate: (map['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      defaultHourlyRate: (map['defaultHourlyRate'] as num?)?.toDouble() ?? 0.0,
      bankName: map['bankName'] ?? '',
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      routingNumber: map['routingNumber'],
      profileType: map['profileType'] ?? 0,
    );
  }

  InvoiceSettings copyWith({
    String? userId,
    String? companyName,
    String? companyAddress,
    String? companyEmail,
    String? companyPhone,
    String? logoPath,
    double? defaultTaxRate,
    double? defaultHourlyRate,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? routingNumber,
    int? profileType,
  }) {
    return InvoiceSettings(
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      logoPath: logoPath ?? this.logoPath,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      profileType: profileType ?? this.profileType,
    );
  }

  factory InvoiceSettings.empty() {
    return InvoiceSettings(
      userId: null,
      companyName: '',
      companyAddress: '',
      companyEmail: '',
      companyPhone: '',
      bankName: '',
      accountName: '',
      accountNumber: '',
      profileType: 0,
    );
  }
}
