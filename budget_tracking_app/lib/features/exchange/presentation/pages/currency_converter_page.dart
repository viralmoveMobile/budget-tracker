import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/exchange_provider.dart';
import '../../domain/models/currency.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class CurrencyConverterPage extends ConsumerStatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  ConsumerState<CurrencyConverterPage> createState() =>
      _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends ConsumerState<CurrencyConverterPage> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(exchangeProvider);
    _amountController =
        TextEditingController(text: initialState.amount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeState = ref.watch(exchangeProvider);
    final notifier = ref.read(exchangeProvider.notifier);

    final stateAmountText =
        exchangeState.amount == 0 ? '' : exchangeState.amount.toString();
    if (_amountController.text != stateAmountText &&
        !FocusScope.of(context).hasFocus) {
      _amountController.text = stateAmountText;
    }

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: const AppAppBar(
        title: Text('Currency Converter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      heroContent: Padding(
        padding: AppSpacing.listItemPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // From currency pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    exchangeState.fromCurrency.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_right_alt_rounded,
                      color: Colors.white.withOpacity(0.8), size: 24),
                ),
                // To currency pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    exchangeState.toCurrency.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '1 ${exchangeState.fromCurrency.code} = ${exchangeState.rate.toStringAsFixed(4)} ${exchangeState.toCurrency.code}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConversionCard(context, exchangeState, notifier),
            AppSpacing.gapXl,
            _buildPopularCurrencies(context, notifier),
            AppSpacing.gapXl,
            _buildRateInfoCard(context, exchangeState),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(
      BuildContext context, ExchangeState state, ExchangeNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // FROM
          _buildCurrencyRow(
            context: context,
            label: 'FROM',
            currency: state.fromCurrency,
            value: state.amount,
            isInput: true,
            onChanged: (val) {
              final amount = double.tryParse(val) ?? 0.0;
              notifier.updateAmount(amount);
            },
            onCurrencyTap: () => _showCurrencyPicker(context, true, notifier),
          ),

          AppSpacing.gapLg,

          // Swap button
          Center(
            child: GestureDetector(
              onTap: () {
                notifier.swapCurrencies();
                HapticFeedback.lightImpact();
                Future.microtask(() {
                  final newState = ref.read(exchangeProvider);
                  _amountController.text = newState.amount.toString();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.swap_vert_rounded,
                    color: Colors.white, size: 22),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.forward())
                .rotate(begin: 0, end: 0, duration: 300.ms),
          ),

          AppSpacing.gapLg,

          // TO
          _buildCurrencyRow(
            context: context,
            label: 'TO',
            currency: state.toCurrency,
            value: state.result,
            isInput: false,
            onChanged: null,
            onCurrencyTap: () => _showCurrencyPicker(context, false, notifier),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildCurrencyRow({
    required BuildContext context,
    required String label,
    required Currency currency,
    required double value,
    required bool isInput,
    required ValueChanged<String>? onChanged,
    required VoidCallback onCurrencyTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Currency selector
        GestureDetector(
          onTap: onCurrencyTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.r16),
              border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withOpacity(0.7),
                        letterSpacing: 0.5)),
                AppSpacing.gapXs,
                Row(
                  children: [
                    Text(
                      currency.code,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppTheme.primaryColor),
                    ),
                    AppSpacing.gapXs,
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primaryColor, size: 18),
                  ],
                ),
                Text(currency.symbol,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor.withOpacity(0.6))),
              ],
            ),
          ),
        ),

        AppSpacing.gapLg,

        // Amount / result
        Expanded(
          child: isInput
              ? TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                        color: AppTheme.textPrimary.withOpacity(0.2),
                        fontWeight: FontWeight.bold,
                        fontSize: 30),
                  ),
                  onChanged: onChanged,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor),
                    ).animate(target: value).shimmer(duration: 600.ms),
                    Text(
                      currency.name,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPopularCurrencies(
      BuildContext context, ExchangeNotifier notifier) {
    final popular = [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'AUD',
      'CAD',
      'LKR',
      'INR',
      'AED'
    ];
    final state = ref.watch(exchangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Popular Currencies',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: popular.map((code) {
            final isActive = state.toCurrency.code == code;
            return GestureDetector(
              onTap: () {
                final currency =
                    Currency.all.where((c) => c.code == code).firstOrNull;
                if (currency != null) {
                  notifier.setToCurrency(currency);
                  HapticFeedback.selectionClick();
                }
              },
              child: AnimatedContainer(
                duration: 200.ms,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.r24),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isActive ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildRateInfoCard(BuildContext context, ExchangeState state) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_graph_rounded,
                    color: AppTheme.primaryColor, size: 18),
              ),
              AppSpacing.gapMd,
              const Text('Exchange Rate',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1 ${state.fromCurrency.code}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                  Text(state.fromCurrency.name,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              const Icon(Icons.arrow_right_alt_rounded,
                  color: AppTheme.primaryColor, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${state.rate.toStringAsFixed(4)} ${state.toCurrency.code}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                  Text(state.toCurrency.name,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  void _showCurrencyPicker(
      BuildContext context, bool isFrom, ExchangeNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) => Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.currency_exchange_rounded,
                          color: AppTheme.primaryColor, size: 18),
                    ),
                    AppSpacing.gapMd,
                    Text(
                      isFrom ? 'Select From Currency' : 'Select To Currency',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: Currency.all.length,
                  itemBuilder: (context, index) {
                    final c = Currency.all[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          c.code[0],
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      subtitle: Text(c.code,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: Text(c.symbol,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 16)),
                      onTap: () {
                        if (isFrom) {
                          notifier.setFromCurrency(c).then((_) {
                            _amountController.text =
                                ref.read(exchangeProvider).amount.toString();
                          });
                        } else {
                          notifier.setToCurrency(c);
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
