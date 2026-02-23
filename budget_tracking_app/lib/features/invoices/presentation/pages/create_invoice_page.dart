import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/invoice_item.dart';
import 'invoice_preview_page.dart';

class CreateInvoicePage extends ConsumerStatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  ConsumerState<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends ConsumerState<CreateInvoicePage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Client Controllers
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();

  // Invoice Info
  final _invoiceNumberController = TextEditingController(
      text:
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  double _taxRate = 0.0;
  double _defaultHourlyRate = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(invoiceSettingsProvider).asData?.value;
      final existingInvoice = ref.read(currentInvoiceProvider);

      setState(() {
        if (settings != null) {
          _taxRate = settings.defaultTaxRate;
          _defaultHourlyRate = settings.defaultHourlyRate;
        }

        if (existingInvoice != null) {
          _clientNameController.text = existingInvoice.clientName;
          _clientEmailController.text = existingInvoice.clientEmail ?? '';
          _clientAddressController.text = existingInvoice.clientAddress ?? '';
          _invoiceNumberController.text =
              'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'; // New number for "copy"
          _issueDate = DateTime.now();
          _dueDate = DateTime.now().add(const Duration(days: 14));
          _taxRate = existingInvoice.tax / existingInvoice.subtotal * 100;
          _items.addAll(
              existingInvoice.items.map((i) => i.copyWith(invoiceId: 'temp')));
        }
      });
    });
  }

  // Items
  final List<InvoiceItem> _items = [];

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddItemSheet(
        defaultHourlyRate: _defaultHourlyRate,
        onAdd: (item) {
          setState(() {
            _items.add(InvoiceItem.create(
              invoiceId: 'temp',
              description: item.description,
              quantity: item.quantity,
              rate: item.rate,
            ));
          });
        },
      ),
    );
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _total => _subtotal * (1 + _taxRate / 100);

  void _finish() {
    final invoice = Invoice.create(
      invoiceNumber: _invoiceNumberController.text,
      issueDate: _issueDate,
      dueDate: _dueDate,
      clientName: _clientNameController.text,
      clientEmail: _clientEmailController.text.isEmpty
          ? null
          : _clientEmailController.text,
      clientAddress: _clientAddressController.text.isEmpty
          ? null
          : _clientAddressController.text,
      taxRate: _taxRate,
      items: _items,
    );

    ref.read(currentInvoiceProvider.notifier).state = invoice;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InvoicePreviewPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _finish();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          Step(
            title: const Text('Client'),
            isActive: _currentStep >= 0,
            content: _buildClientStep(),
          ),
          Step(
            title: const Text('Items'),
            isActive: _currentStep >= 1,
            content: _buildItemsStep(context),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            content: _buildReviewStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _clientNameController,
            decoration: const InputDecoration(
                labelText: 'Client Name *', border: OutlineInputBorder()),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clientEmailController,
            decoration: const InputDecoration(
                labelText: 'Client Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clientAddressController,
            decoration: const InputDecoration(
                labelText: 'Client Address', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _invoiceNumberController,
            decoration: const InputDecoration(
                labelText: 'Invoice Number', border: OutlineInputBorder()),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildItemsStep(BuildContext context) {
    return Column(
      children: [
        if (_items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('No items added yet',
                style: TextStyle(
                    color: AppTheme.getTextColor(context, isSecondary: true))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                title: Text(item.description),
                subtitle: Text(
                    '${item.quantity} x \$${item.rate.toStringAsFixed(2)}'),
                trailing: Text('\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onLongPress: () => setState(() => _items.removeAt(index)),
              );
            },
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        _buildSummaryRow('Subtotal', _subtotal),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tax Rate (%)'),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: _taxRate.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                onChanged: (val) =>
                    setState(() => _taxRate = double.tryParse(val) ?? 0.0),
                decoration: const InputDecoration(isDense: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSummaryRow('Tax Amount', _subtotal * (_taxRate / 100)),
        const Divider(height: 32),
        _buildSummaryRow('Grand Total', _total, isBold: true),
        const SizedBox(height: 32),
        ListTile(
          title: const Text('Due Date'),
          subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : null,
                fontSize: isBold ? 18 : 16)),
        Text('\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : null,
                fontSize: isBold ? 18 : 16)),
      ],
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final double defaultHourlyRate;
  final Function(InvoiceItem) onAdd;
  const _AddItemSheet({required this.onAdd, required this.defaultHourlyRate});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  late final _rateController =
      TextEditingController(text: widget.defaultHourlyRate.toString());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _qtyController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(
                  child: TextField(
                      controller: _rateController,
                      decoration: const InputDecoration(labelText: 'Rate'),
                      keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_descController.text.isNotEmpty &&
                  _rateController.text.isNotEmpty) {
                widget.onAdd(InvoiceItem.create(
                  invoiceId: '',
                  description: _descController.text,
                  quantity: double.tryParse(_qtyController.text) ?? 1.0,
                  rate: double.tryParse(_rateController.text) ?? 0.0,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add to Invoice'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
