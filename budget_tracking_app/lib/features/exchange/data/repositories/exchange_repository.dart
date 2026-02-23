import 'package:budget_tracking_app/features/exchange/domain/models/currency.dart';
import '../services/currency_api_service.dart';

class ExchangeRepository {
  final _apiService = CurrencyApiService();

  Future<List<Currency>> getSupportedCurrencies() async {
    return Currency.all;
  }

  Future<double> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;
    return _apiService.getRate(from, to);
  }

  Future<double> convert(double amount, String from, String to) async {
    if (from == to) return amount;
    final rate = await getExchangeRate(from, to);
    return amount * rate;
  }

  DateTime getLastUpdated() {
    // In a real app, this would be stored in metadata or returned from the API
    return DateTime.now();
  }
}
