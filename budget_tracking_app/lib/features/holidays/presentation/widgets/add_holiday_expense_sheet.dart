import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/holiday_provider.dart';
import '../../domain/models/holiday_expense.dart';
import '../../../common/services/location_service.dart';
import '../../../../features/exchange/presentation/providers/exchange_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class AddHolidayExpenseSheet extends ConsumerStatefulWidget {
  final String holidayId;

  const AddHolidayExpenseSheet({super.key, required this.holidayId});

  @override
  ConsumerState<AddHolidayExpenseSheet> createState() =>
      _AddHolidayExpenseSheetState();
}

class _AddHolidayExpenseSheetState
    extends ConsumerState<AddHolidayExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _localAmountController = TextEditingController();
  final _primaryAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  HolidayExpenseCategory _category = HolidayExpenseCategory.food;
  DateTime _date = DateTime.now();
  String _selectedCurrency = 'USD';
  String? _receiptPath;
  String? _homeCurrency;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initHomeCurrency();
  }

  Future<void> _initHomeCurrency() async {
    // Current location for the transaction
    final locationCurrency = await ref
        .read(locationServiceProvider)
        .getCurrentLocationCurrencyCode();
    // User's permanent primary currency
    final primaryCurrency = await ref.read(primaryCurrencyProvider.future);

    if (mounted) {
      setState(() {
        _homeCurrency = primaryCurrency;
        _selectedCurrency = locationCurrency;
      });
    }
  }

  void _onLocalAmountChanged(String value) async {
    if (_isSyncing || value.isEmpty || _homeCurrency == null) {
      if (value.isEmpty) _primaryAmountController.clear();
      return;
    }

    final amount = double.tryParse(value);
    if (amount == null) return;

    _isSyncing = true;
    try {
      if (_selectedCurrency == _homeCurrency) {
        _primaryAmountController.text = value;
      } else {
        final repo = ref.read(exchangeRepositoryProvider);
        final converted =
            await repo.convert(amount, _selectedCurrency, _homeCurrency!);
        _primaryAmountController.text = converted.toStringAsFixed(2);
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _onPrimaryAmountChanged(String value) async {
    if (_isSyncing || value.isEmpty || _homeCurrency == null) {
      if (value.isEmpty) _localAmountController.clear();
      return;
    }

    final amount = double.tryParse(value);
    if (amount == null) return;

    _isSyncing = true;
    try {
      if (_selectedCurrency == _homeCurrency) {
        _localAmountController.text = value;
      } else {
        final repo = ref.read(exchangeRepositoryProvider);
        // Convert from Primary to Local
        final converted =
            await repo.convert(amount, _homeCurrency!, _selectedCurrency);
        _localAmountController.text = converted.toStringAsFixed(2);
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _localAmountController.dispose();
    _primaryAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _receiptPath = image.path);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final localAmount = double.tryParse(_localAmountController.text) ?? 0.0;
      final primaryAmount =
          double.tryParse(_primaryAmountController.text) ?? 0.0;

      final expense = HolidayExpense(
        id: const Uuid().v4(),
        holidayId: widget.holidayId,
        amount: primaryAmount, // Primary currency amount for database
        originalAmount: _selectedCurrency != _homeCurrency ? localAmount : null,
        currency: _selectedCurrency,
        category: _category,
        date: _date,
        description: _descriptionController.text,
        receiptPath: _receiptPath,
      );

      ref.read(holidayExpensesNotifierProvider).addExpense(expense);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context, opacity: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add Holiday Expense',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_homeCurrency != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Primary Currency: $_homeCurrency',
                    style: TextStyle(
                      color: AppTheme.getTextColor(context, opacity: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              AppSpacing.gapXxl,
              // Local Currency Field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildModernTextField(
                      controller: _localAmountController,
                      label: 'Amount (${_selectedCurrency})',
                      icon: Icons.location_on_rounded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onLocalAmountChanged,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null)
                          return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        labelStyle: TextStyle(
                            color: AppTheme.getTextColor(context,
                                isSecondary: true)),
                        filled: true,
                        fillColor:
                            AppTheme.getBorderColor(context, opacity: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r16),
                          borderSide: BorderSide(
                              color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      items: [
                        'USD',
                        'EUR',
                        'GBP',
                        'JPY',
                        'AUD',
                        'CAD',
                        'LKR',
                        'INR',
                        'AED',
                        'SGD'
                      ]
                          .map((code) => DropdownMenuItem(
                                value: code,
                                child: Text(code,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrency = value);
                          _onLocalAmountChanged(_localAmountController.text);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Primary Currency Field (Calculated/Synched)
              if (_homeCurrency != null && _selectedCurrency != _homeCurrency)
                _buildModernTextField(
                  controller: _primaryAmountController,
                  label: 'Amount in ${_homeCurrency} (Primary)',
                  icon: Icons.home_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onPrimaryAmountChanged,
                  fillColor: AppTheme.primaryColor.withOpacity(0.05),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (double.tryParse(val) == null) return 'Invalid amount';
                    return null;
                  },
                )
              else if (_homeCurrency == null)
                const Center(child: CircularProgressIndicator())
              else
                const SizedBox.shrink(),
              if (_homeCurrency != null && _selectedCurrency != _homeCurrency)
                const SizedBox(height: 20),

              DropdownButtonFormField<HolidayExpenseCategory>(
                value: _category,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryColor),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                      color: AppTheme.getTextColor(context, isSecondary: true)),
                  filled: true,
                  fillColor: AppTheme.getBorderColor(context, opacity: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                items: HolidayExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color),
                        AppSpacing.gapMd,
                        Text(cat.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(AppSpacing.r16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _receiptPath == null
                              ? Colors.transparent
                              : AppTheme.successColor.withOpacity(0.1),
                          border: Border.all(
                            color: _receiptPath == null
                                ? AppTheme.getBorderColor(context)!
                                : AppTheme.successColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.r16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                _receiptPath == null
                                    ? Icons.camera_alt_rounded
                                    : Icons.check_circle_rounded,
                                color: _receiptPath == null
                                    ? AppTheme.primaryColor
                                    : AppTheme.successColor),
                            AppSpacing.gapSm,
                            Text(
                                _receiptPath == null
                                    ? 'Capture Receipt'
                                    : 'Receipt Captured',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _receiptPath == null
                                      ? AppTheme.primaryColor
                                      : AppTheme.successColor,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_receiptPath != null) ...[
                    AppSpacing.gapMd,
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _receiptPath = null),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.dangerColor),
                        tooltip: 'Remove Receipt',
                      ),
                    ),
                  ],
                ],
              ),
              if (_receiptPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                    child: Image.file(
                      File(_receiptPath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              AppSpacing.gapXxl,
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                  ),
                ),
                child: const Text('Add Expense',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: AppTheme.getTextColor(context, isSecondary: true)),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: fillColor ?? AppTheme.getBorderColor(context, opacity: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: AppTheme.dangerColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: AppTheme.dangerColor, width: 2),
        ),
      ),
    );
  }
}
