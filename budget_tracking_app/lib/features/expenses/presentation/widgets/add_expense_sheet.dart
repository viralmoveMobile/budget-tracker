import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/presentation/widgets/add_account_sheet.dart';
import '../../../common/services/location_service.dart';
import '../../../../features/exchange/presentation/providers/exchange_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? expense;

  const AddExpenseSheet({super.key, this.expense});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedCurrency;
  late bool _isIncome;
  String? _selectedAccountId;
  double? _convertedAmount;
  String? _homeCurrency;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _selectedCategory = widget.expense?.category ?? ExpenseCategory.food;
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCurrency = widget.expense?.currency ?? 'USD';
    _isIncome = widget.expense?.isIncome ?? false;
    _selectedAccountId = widget.expense?.linkedAccount;

    // Listen to changes to update conversion
    _amountController.addListener(_updateConversion);

    // Initial home currency detection
    _initHomeCurrency();
  }

  Future<void> _initHomeCurrency() async {
    final locationCurrency = await ref
        .read(locationServiceProvider)
        .getCurrentLocationCurrencyCode();
    final primaryCurrency = await ref.read(primaryCurrencyProvider.future);

    if (mounted) {
      setState(() {
        _homeCurrency = primaryCurrency;
        if (widget.expense == null) {
          _selectedCurrency = locationCurrency;
        }
      });
      _updateConversion();
    }
  }

  void _updateConversion() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty ||
        _homeCurrency == null ||
        _selectedCurrency == _homeCurrency) {
      if (mounted) setState(() => _convertedAmount = null);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    final repo = ref.read(exchangeRepositoryProvider);
    final converted =
        await repo.convert(amount, _selectedCurrency, _homeCurrency!);

    if (mounted) {
      setState(() => _convertedAmount = converted);
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateConversion);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      final expense = Expense(
        id: widget.expense?.id ?? const Uuid().v4(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        currency: _selectedCurrency,
        isIncome: _isIncome,
        linkedAccount: _selectedAccountId,
      );

      if (widget.expense == null) {
        ref.read(expensesProvider.notifier).addExpense(expense);
      } else {
        ref.read(expensesProvider.notifier).updateExpense(expense);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.expense == null ? 'Add Expense' : 'Edit Expense',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapXl,
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Expense'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Income'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_isIncome},
                  onSelectionChanged: (value) {
                    setState(() => _isIncome = value.first);
                  },
                ),
                AppSpacing.gapLg,
                const Text(
                  'Source Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                AppSpacing.gapSm,
                ref.watch(accountsProvider).when(
                      data: (accounts) => Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAccountId,
                              decoration: const InputDecoration(
                                hintText: 'Select Account',
                                prefixIcon:
                                    Icon(Icons.account_balance_wallet_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Default (General)'),
                                ),
                                ...accounts.map((account) {
                                  return DropdownMenuItem(
                                    value: account.id,
                                    child: Text(account.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedAccountId = value);
                              },
                            ),
                          ),
                          AppSpacing.gapSm,
                          IconButton.filledTonal(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const AddAccountSheet(),
                              );
                            },
                            icon: const Icon(Icons.add),
                            tooltip: 'Add New Account',
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, st) => Text(
                        'Error loading accounts: $err',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                AppSpacing.gapLg,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    AppSpacing.gapMd,
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
                        ].map((code) {
                          return DropdownMenuItem(
                            value: code,
                            child: Text(code,
                                style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCurrency = value);
                            _updateConversion();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_convertedAmount != null && _homeCurrency != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      '≈ ${_convertedAmount!.toStringAsFixed(2)} $_homeCurrency (Live Conversion)',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                AppSpacing.gapLg,
                DropdownButtonFormField<ExpenseCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ExpenseCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color),
                          AppSpacing.gapSm,
                          Text(category.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null)
                      setState(() => _selectedCategory = value);
                  },
                ),
                AppSpacing.gapLg,
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  ),
                ),
                AppSpacing.gapLg,
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                AppSpacing.gapXl,
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                      widget.expense == null ? 'Add Expense' : 'Save Changes'),
                ),
                AppSpacing.gapLg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
