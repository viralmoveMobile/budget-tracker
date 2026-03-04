import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currencyApiServiceProvider = Provider((ref) => CurrencyApiService());

class CurrencyApiService {
  // Using a reliable public API: ExchangeRate-API (Free tier allows 1,500 requests/month)
  // For "one second" updates, we will simulate the live feel while pulsing the API at a reasonable frequency (e.g., every 5-10 mins)
  // and using interpolation or mock jitter if visually necessary, to respect API limits.
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  Map<String, double>? _cachedRates;
  DateTime? _lastFetch;

  Future<Map<String, double>> getLatestRates(String baseCurrency) async {
    final now = DateTime.now();

    // Cache for 5 minutes instead of 30 for more "real-time" feel
    if (_cachedRates != null &&
        _lastFetch != null &&
        now.difference(_lastFetch!).inMinutes < 5) {
      return _cachedRates!;
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$baseCurrency'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = Map<String, double>.from(
              (data['rates'] as Map).map((k, v) => MapEntry(k, v.toDouble())));
          _cachedRates = rates;
          _lastFetch = now;
          return rates;
        }
      }
    } catch (e) {
      print('Error fetching rates: $e');
    }

    return _cachedRates ?? {'USD': 1.0};
  }

  Future<Map<String, double>> getRateMap(String baseCurrency) async {
    return getLatestRates(baseCurrency);
  }

  Future<double> getRate(String from, String to) async {
    final rates = await getLatestRates(from);
    return rates[to] ?? 1.0;
  }
}

final exchangeRatesProvider =
    FutureProvider.family<double, Map<String, String>>((ref, params) async {
  final from = params['from'] ?? 'USD';
  final to = params['to'] ?? 'LKR';
  return ref.watch(currencyApiServiceProvider).getRate(from, to);
});
