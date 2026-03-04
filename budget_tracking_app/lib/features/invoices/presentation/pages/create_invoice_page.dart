import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/invoice_item.dart';
import 'invoice_preview_page.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

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

  // Items
  final List<InvoiceItem> _items = [];

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
      backgroundColor: Colors.transparent,
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
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client Name is required')),
      );
      setState(() => _currentStep = 0);
      return;
    }

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
    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: const AppAppBar(
        title: Text('New Invoice',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      heroContent: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStepIndicator(0, 'Client', Icons.person_rounded),
            _buildStepConnector(0),
            _buildStepIndicator(1, 'Items', Icons.list_alt_rounded),
            _buildStepConnector(1),
            _buildStepIndicator(2, 'Review', Icons.check_circle_rounded),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: 300.ms,
                child: _buildCurrentStepView(),
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label, IconData icon) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Column(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            color: isActive || isCompleted
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    return Flexible(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        color: isCompleted ? Colors.white : Colors.white.withOpacity(0.2),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildClientStep();
      case 1:
        return _buildItemsStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r16)),
                  ),
                  child: const Text('Back',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (_currentStep > 0) AppSpacing.gapLg,
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentStep == 0 && !_formKey.currentState!.validate()) {
                    return;
                  }
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _finish();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r16)),
                ),
                child: Text(
                  _currentStep == 2 ? 'Generate Preview' : 'Continue',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('client_step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Client Details',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          AppSpacing.gapLg,
          _buildTextField(
            controller: _clientNameController,
            label: 'Client Name *',
            icon: Icons.person_outline_rounded,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          AppSpacing.gapLg,
          _buildTextField(
            controller: _clientEmailController,
            label: 'Email (Optional)',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          AppSpacing.gapLg,
          _buildTextField(
            controller: _clientAddressController,
            label: 'Billing Address (Optional)',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),
          AppSpacing.gapXxl,
          const Text('Invoice Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          AppSpacing.gapLg,
          _buildTextField(
            controller: _invoiceNumberController,
            label: 'Invoice Number',
            icon: Icons.tag_rounded,
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildItemsStep() {
    return Column(
      key: const ValueKey('items_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Line Items',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Item',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 60, color: AppTheme.primaryColor.withOpacity(0.2)),
                AppSpacing.gapLg,
                const Text('No line items added',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                AppSpacing.gapSm,
                const Text('Add services or products to this invoice.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => AppSpacing.gapMd,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.r16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                      ),
                      child: const Icon(Icons.sell_rounded,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                    AppSpacing.gapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                          AppSpacing.gapXs,
                          Text(
                              '${item.quantity} x \$${item.rate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.primaryColor)),
                        AppSpacing.gapXs,
                        GestureDetector(
                          onTap: () => setState(() => _items.removeAt(index)),
                          child: const Text('Remove',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.dangerColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0);
            },
          ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildReviewStep() {
    return Column(
      key: const ValueKey('review_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Invoice Summary',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        AppSpacing.gapLg,
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow('Subtotal', _subtotal),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax Rate (%)',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: TextFormField(
                      initialValue: _taxRate.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: AppTheme.primaryColor.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(
                          () => _taxRate = double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _buildSummaryRow('Tax Amount', _subtotal * (_taxRate / 100)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 1),
              ),
              _buildSummaryRow('Grand Total', _total,
                  isTotal: true, color: AppTheme.primaryColor),
            ],
          ),
        ),
        AppSpacing.gapXl,
        const Text('Dates & Terms',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        AppSpacing.gapLg,
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded,
                      color: AppTheme.primaryColor),
                ),
                title: const Text('Issue Date',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Text(DateFormat('dd MMM yyyy').format(_issueDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary)),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_busy_rounded,
                      color: AppTheme.dangerColor),
                ),
                title: const Text('Due Date',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(_dueDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dangerColor)),
                    AppSpacing.gapSm,
                    const Icon(Icons.edit_calendar_rounded,
                        size: 16, color: AppTheme.dangerColor),
                  ],
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.primaryColor,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, Color color = AppTheme.textPrimary}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
                color: isTotal ? color : AppTheme.textSecondary,
                fontSize: isTotal ? 16 : 14)),
        Text('\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
                color: color,
                fontSize: isTotal ? 24 : 16)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon:
            maxLines == 1 ? Icon(icon, color: AppTheme.primaryColor) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: const BorderSide(color: AppTheme.dangerColor),
        ),
      ),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Line Item',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          AppSpacing.gapXl,
          _buildField(
            controller: _descController,
            label: 'Description / Service',
            icon: Icons.edit_note_rounded,
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _qtyController,
                  label: 'Qty / Hours',
                  icon: Icons.numbers_rounded,
                  isNumber: true,
                ),
              ),
              AppSpacing.gapLg,
              Expanded(
                child: _buildField(
                  controller: _rateController,
                  label: 'Rate / Price',
                  icon: Icons.monetization_on_rounded,
                  isNumber: true,
                ),
              ),
            ],
          ),
          AppSpacing.gapXxl,
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
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r16)),
            ),
            child: const Text('Add to Invoice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          AppSpacing.gapXxl,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
