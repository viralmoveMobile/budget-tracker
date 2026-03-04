import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats the given [amount] with the specified [currencyCode].
  /// Ensures exactly two decimal places and a space between the symbol and the amount.
  static String format(double amount, String currencyCode) {
    try {
      final symbol = NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
      return NumberFormat.currency(
        name: currencyCode,
        symbol: '$symbol ', // Adds the required space
        decimalDigits: 2, // Forces 2 decimals universally
      ).format(amount);
    } catch (e) {
      // Fallback in case of an invalid currency code
      return '\$ ${amount.toStringAsFixed(2)}';
    }
  }
}
