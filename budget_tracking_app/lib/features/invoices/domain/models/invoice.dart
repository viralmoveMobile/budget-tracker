import 'package:uuid/uuid.dart';
import 'invoice_item.dart';

enum InvoiceStatus { paid, unpaid }

class Invoice {
  final String id;
  final String? userId; // Added for multi-user isolation
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final String clientName;
  final String? clientEmail;
  final String? clientAddress;
  final double subtotal;
  final double tax;
  final double total;
  final List<InvoiceItem> items;
  final InvoiceStatus status;
  final int profileType;

  Invoice({
    required this.id,
    this.userId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.clientName,
    this.clientEmail,
    this.clientAddress,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
    this.status = InvoiceStatus.unpaid,
    this.profileType = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientAddress': clientAddress,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status.name,
      'profileType': profileType,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map,
      {List<InvoiceItem> items = const []}) {
    return Invoice(
      id: map['id'],
      userId: map['userId'],
      invoiceNumber: map['invoiceNumber'],
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: DateTime.parse(map['dueDate']),
      clientName: map['clientName'],
      clientEmail: map['clientEmail'],
      clientAddress: map['clientAddress'],
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      items: items,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'unpaid'),
        orElse: () => InvoiceStatus.unpaid,
      ),
      profileType: map['profileType'] ?? 0,
    );
  }

  factory Invoice.create({
    String? userId,
    required String invoiceNumber,
    required DateTime issueDate,
    required DateTime dueDate,
    required String clientName,
    String? clientEmail,
    String? clientAddress,
    required double taxRate,
    required List<InvoiceItem> items,
    InvoiceStatus status = InvoiceStatus.unpaid,
    int profileType = 0,
  }) {
    final id = const Uuid().v4();
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final tax = subtotal * (taxRate / 100);
    final total = subtotal + tax;

    // Propagate the new invoice ID and userId to all items
    final updatedItems = items
        .map((item) => item.copyWith(invoiceId: id, userId: userId))
        .toList();

    return Invoice(
      id: id,
      userId: userId,
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
      dueDate: dueDate,
      clientName: clientName,
      clientEmail: clientEmail,
      clientAddress: clientAddress,
      subtotal: subtotal,
      tax: tax,
      total: total,
      items: updatedItems,
      status: status,
      profileType: profileType,
    );
  }

  Invoice copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    String? clientName,
    String? clientEmail,
    String? clientAddress,
    double? subtotal,
    double? tax,
    double? total,
    List<InvoiceItem>? items,
    InvoiceStatus? status,
    int? profileType,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      items: items ?? this.items,
      status: status ?? this.status,
      profileType: profileType ?? this.profileType,
    );
  }
}
