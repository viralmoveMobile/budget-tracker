import 'package:uuid/uuid.dart';

class InvoiceItem {
  final String id;
  final String? userId; // Added for multi-user isolation
  final String invoiceId;
  final String description;
  final double quantity;
  final double rate;
  final double total;

  InvoiceItem({
    required this.id,
    this.userId,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.total,
  });

  InvoiceItem copyWith({
    String? id,
    String? userId,
    String? invoiceId,
    String? description,
    double? quantity,
    double? rate,
    double? total,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'invoiceId': invoiceId,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      userId: map['userId'],
      invoiceId: map['invoiceId'],
      description: map['description'],
      quantity: map['quantity'],
      rate: map['rate'],
      total: map['total'],
    );
  }

  factory InvoiceItem.create({
    String? userId,
    required String invoiceId,
    required String description,
    required double quantity,
    required double rate,
  }) {
    return InvoiceItem(
      id: const Uuid().v4(),
      userId: userId,
      invoiceId: invoiceId,
      description: description,
      quantity: quantity,
      rate: rate,
      total: quantity * rate,
    );
  }
}
