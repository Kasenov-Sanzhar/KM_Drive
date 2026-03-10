import 'package:intl/intl.dart';
import 'date_formatter.dart';

abstract class KmFormatters {
  KmFormatters._();

  static String tenge(int amount, {bool perMonth = false}) {
    final formatted = NumberFormat('#,##0', 'ru_RU').format(amount);
    return perMonth ? '$formatted ₸/мес' : '$formatted ₸';
  }

  static String kilometers(int km) {
    final formatted = NumberFormat('#,##0', 'ru_RU').format(km);
    return '$formatted км';
  }

  static String percent(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  static String fuelConsumption(double liters) {
    return '${liters.toStringAsFixed(1)} л/100км';
  }

  static String driveTime(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '$m мин';      // Исправлено: было '${m}мин'
    if (m == 0) return '$h ч';        // Исправлено: было '${h}ч'
    return '$h ч $m мин';              // Исправлено: было '${h}ч ${m}мин'
  }

  static String date(DateTime d) {
    return DateFormatter.date(d);
  }

  static String dateShort(DateTime d) {
    return DateFormatter.dateShort(d);
  }
}