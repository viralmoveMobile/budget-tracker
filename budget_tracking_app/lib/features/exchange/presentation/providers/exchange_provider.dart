import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_tracking_app/features/exchange/domain/models/currency.dart';
import 'package:budget_tracking_app/features/exchange/data/repositories/exchange_repository.dart';

final exchangeRepositoryProvider = Provider((ref) => ExchangeRepository());

class ExchangeState {
  final Currency fromCurrency;
  final Currency toCurrency;
  final double amount;
  final double result;
  final double rate;
  final DateTime lastUpdated;

  ExchangeState({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.result,
    required this.rate,
    required this.lastUpdated,
  });

  ExchangeState copyWith({
    Currency? fromCurrency,
    Currency? toCurrency,
    double? amount,
    double? result,
    double? rate,
    DateTime? lastUpdated,
  }) {
    return ExchangeState(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      result: result ?? this.result,
      rate: rate ?? this.rate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ExchangeNotifier extends StateNotifier<ExchangeState> {
  final ExchangeRepository _repository;

  ExchangeNotifier(this._repository)
      : super(ExchangeState(
          fromCurrency: Currency.usd,
          toCurrency: Currency.lkr, // Default to common local currency
          amount: 1.0,
          result: 300.0,
          rate: 300.0,
          lastUpdated: DateTime.now(),
        )) {
    _init();
  }

  Future<void> _init() async {
    final rate = await _repository.getExchangeRate(
      state.fromCurrency.code,
      state.toCurrency.code,
    );
    if (!mounted) return;
    state = state.copyWith(
      rate: rate,
      result: state.amount * rate,
      lastUpdated: _repository.getLastUpdated(),
    );
  }

  Future<void> updateAmount(double amount) async {
    state = state.copyWith(
      amount: amount,
      result: amount * state.rate,
    );
  }

  Future<void> setFromCurrency(Currency currency) async {
    final rate = await _repository.getExchangeRate(
      currency.code,
      state.toCurrency.code,
    );
    if (!mounted) return;
    state = state.copyWith(
      fromCurrency: currency,
      rate: rate,
      result: state.amount * rate,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> setToCurrency(Currency currency) async {
    final rate = await _repository.getExchangeRate(
      state.fromCurrency.code,
      currency.code,
    );
    if (!mounted) return;
    state = state.copyWith(
      toCurrency: currency,
      rate: rate,
      result: state.amount * rate,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> swapCurrencies() async {
    final newFrom = state.toCurrency;
    final newTo = state.fromCurrency;
    final rate = await _repository.getExchangeRate(
      newFrom.code,
      newTo.code,
    );
    if (!mounted) return;
    state = state.copyWith(
      fromCurrency: newFrom,
      toCurrency: newTo,
      rate: rate,
      result: state.amount * rate,
      lastUpdated: DateTime.now(),
    );
  }
}

final exchangeProvider =
    StateNotifierProvider<ExchangeNotifier, ExchangeState>((ref) {
  final repository = ref.watch(exchangeRepositoryProvider);
  return ExchangeNotifier(repository);
});
