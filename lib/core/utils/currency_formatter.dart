import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
