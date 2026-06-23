import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const Map<String, int> _decimalPlaces = {
    'XOF': 0, 'XAF': 0, 'GNF': 0,
    'GHS': 2, 'LRD': 2, 'SLE': 2, 'CNY': 2,
    'USD': 2, 'EUR': 2,
  };

  static const Map<String, String> _symbols = {
    'XOF': 'CFA', 'XAF': 'CFA', 'GNF': 'FG',
    'GHS': 'GH₵', 'LRD': 'L\$', 'SLE': 'Le',
    'CNY': '¥', 'USD': '\$', 'EUR': '€',
  };

  static String format(double amount, String currencyCode) {
    final decimals = _decimalPlaces[currencyCode] ?? 2;
    final symbol = _symbols[currencyCode] ?? currencyCode;
    final formatted = NumberFormat('#,##0${decimals > 0 ? '.' + '0' * decimals : ''}')
        .format(amount);
    return '$symbol $formatted';
  }

  static String symbol(String currencyCode) =>
      _symbols[currencyCode] ?? currencyCode;

  static int decimals(String currencyCode) =>
      _decimalPlaces[currencyCode] ?? 2;
}
