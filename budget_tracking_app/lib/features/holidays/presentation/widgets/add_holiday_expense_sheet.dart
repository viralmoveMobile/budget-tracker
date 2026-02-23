import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/holiday_provider.dart';
import '../../domain/models/holiday_expense.dart';
import '../../../common/services/location_service.dart';
import '../../../../features/exchange/presentation/providers/exchange_provider.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              // Local Currency Field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _localAmountController,
                      onChanged: _onLocalAmountChanged,
                      decoration: InputDecoration(
                        labelText: 'Amount (${_selectedCurrency})',
                        prefixIcon:
                            const Icon(Icons.location_on_outlined, size: 20),
                        border: const OutlineInputBorder(),
                        helperText: 'Enter local spending',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null)
                          return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              // Primary Currency Field (Calculated/Synched)
              if (_homeCurrency != null && _selectedCurrency != _homeCurrency)
                TextFormField(
                  controller: _primaryAmountController,
                  onChanged: _onPrimaryAmountChanged,
                  decoration: InputDecoration(
                    labelText: 'Amount in ${_homeCurrency} (Primary)',
                    prefixIcon: const Icon(Icons.home_outlined, size: 20),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.blue.withOpacity(0.05),
                    helperText: 'Auto-converted value to save',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<HolidayExpenseCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: HolidayExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color),
                        const SizedBox(width: 12),
                        Text(cat.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(_receiptPath == null
                          ? Icons.camera_alt
                          : Icons.check_circle),
                      label: Text(_receiptPath == null
                          ? 'Capture Receipt'
                          : 'Receipt Captured'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor:
                            _receiptPath == null ? null : Colors.green,
                      ),
                    ),
                  ),
                  if (_receiptPath != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _receiptPath = null),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ],
              ),
              if (_receiptPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_receiptPath!),
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Expense'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
