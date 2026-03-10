import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateFormatter {
  static String _locale = 'ru_RU';

  static Future<void> initialize(String locale) async {
    _locale = locale;
    await initializeDateFormatting(locale, null);
  }

  static String date(DateTime date) {
    return DateFormat('d MMMM yyyy', _locale).format(date);
  }

  static String dateShort(DateTime date) {
    return DateFormat('d MMM yyyy', _locale).format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('d MMMM yyyy, HH:mm', _locale).format(date);
  }
}
