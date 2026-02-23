import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/exchange_provider.dart';
import '../../domain/models/currency.dart';

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

    // Sync controller text with state if updated from elsewhere (e.g. swap)
    // Avoid resetting text if it matches current state or if input is in progress
    final stateAmountText =
        exchangeState.amount == 0 ? '' : exchangeState.amount.toString();
    if (_amountController.text != stateAmountText &&
        !FocusScope.of(context).hasFocus) {
      _amountController.text = stateAmountText;
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Currency Converter',
            style: TextStyle(color: AppTheme.getSurfaceColor(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.exchangeColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildConversionCard(context, exchangeState, notifier),
            const SizedBox(height: 32),
            _buildExchangeRateInfo(context, exchangeState),
            const SizedBox(height: 32),
            _buildQuickActions(context, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(
      BuildContext context, ExchangeState state, ExchangeNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.exchangeColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildCurrencyInput(
              context,
              'From',
              state.fromCurrency,
              state.amount,
              true,
              (val) {
                final amount = double.tryParse(val) ?? 0.0;
                notifier.updateAmount(amount);
              },
              () => _showCurrencyPicker(context, true, notifier),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                const Divider(color: Colors.white10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert_rounded,
                        color: Colors.white),
                    onPressed: () {
                      notifier.swapCurrencies();
                      // Update controller immediately on swap
                      Future.microtask(() {
                        final newState = ref.read(exchangeProvider);
                        _amountController.text = newState.amount.toString();
                      });
                    },
                  )
                      .animate(target: 1)
                      .rotate(begin: 0, end: 0.5, duration: 300.ms),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCurrencyInput(
              context,
              'To',
              state.toCurrency,
              state.result,
              false,
              null,
              () => _showCurrencyPicker(context, false, notifier),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCurrencyInput(
    BuildContext context,
    String label,
    Currency currency,
    double value,
    bool isInput,
    ValueChanged<String>? onChanged,
    VoidCallback onCurrencyTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.getTextColor(context, opacity: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onCurrencyTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(currency.code,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.getTextColor(context))),
                    SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.getTextColor(context, opacity: 0.6), size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: isInput
                  ? TextField(
                      controller: _amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context)),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.1)),
                        suffixText: currency.symbol,
                        suffixStyle: TextStyle(
                            fontSize: 16, color: AppTheme.getTextColor(context, opacity: 0.5)),
                      ),
                      onChanged: onChanged,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.toStringAsFixed(2),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme
                                  .exchangeColor), // Use teal for result
                        ).animate(target: value).shimmer(duration: 400.ms),
                        Text(
                          currency.symbol,
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.getTextColor(context, opacity: 0.6)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExchangeRateInfo(BuildContext context, ExchangeState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exchange Rate', style: TextStyle(color: AppTheme.getTextColor(context, opacity: 0.6))),
              Row(
                children: [
                  Text(
                    '1 ${state.fromCurrency.code}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.getTextColor(context, opacity: 0.5)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_right_alt_rounded,
                        size: 16, color: AppTheme.getTextColor(context, opacity: 0.3)),
                  ),
                  Text(
                    '${state.rate.toStringAsFixed(4)} ${state.toCurrency.code}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.primaryColor.withOpacity(0.1), height: 1),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildQuickActions(BuildContext context, ExchangeNotifier notifier) {
    final popular = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular Currencies',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: popular.map((code) {
            return InkWell(
              onTap: () {
                final currency = Currency.all.firstWhere((c) => c.code == code);
                notifier.setToCurrency(currency);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.getTextColor(context, opacity: 0.15)),
                ),
                child: Text(code,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showCurrencyPicker(
      BuildContext context, bool isFrom, ExchangeNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Currency',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context))),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: Currency.all.length,
                  itemBuilder: (context, index) {
                    final c = Currency.all[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(c.code.substring(0, 1),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                      ),
                      title: Text(c.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextColor(context))),
                      subtitle:
                          Text(c.code, style: TextStyle(color: AppTheme.getTextColor(context, opacity: 0.6))),
                      trailing: Text(c.symbol,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context))),
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
