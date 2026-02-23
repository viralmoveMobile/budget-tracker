class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });

  static const Currency usd =
      Currency(code: 'USD', symbol: '\$', name: 'US Dollar', flag: 'USD');
  static const Currency eur =
      Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: 'EUR');
  static const Currency gbp =
      Currency(code: 'GBP', symbol: '£', name: 'British Pound', flag: 'GBP');
  static const Currency jpy =
      Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: 'JPY');
  static const Currency aud = Currency(
      code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: 'AUD');
  static const Currency cad = Currency(
      code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', flag: 'CAD');
  static const Currency lkr = Currency(
      code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee', flag: 'LKR');
  static const Currency inr =
      Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: 'INR');
  static const Currency aed =
      Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', flag: 'AED');
  static const Currency sgd = Currency(
      code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: 'SGD');

  static List<Currency> get all =>
      [usd, eur, gbp, jpy, aud, cad, lkr, inr, aed, sgd];
}
