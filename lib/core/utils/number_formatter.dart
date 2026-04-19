import 'package:intl/intl.dart';

/// تنسيق الأرقام - Number Formatter
/// تنسيق العملات والأرقام بالعربية
class NumberFormatter {
  NumberFormatter._();

  /// تنسيق العملة - Currency format
  /// مثال: 1,500.00 ج.م
  static String currency(double amount, {String symbol = 'ج.م'}) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} $symbol';
  }

  /// تنسيق العملة بدون كسور - Currency without decimals
  /// مثال: 1,500 ج.م
  static String currencyWhole(double amount, {String symbol = 'ج.م'}) {
    final formatter = NumberFormat('#,##0', 'ar');
    return '${formatter.format(amount)} $symbol';
  }

  /// تنسيق الأرقام الكبيرة - Large number format
  /// مثال: 1.5K, 2.3M
  static String compact(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  /// تنسيق رقم عادي - Standard number format
  /// مثال: 1,500
  static String format(num value) {
    final formatter = NumberFormat('#,##0', 'ar');
    return formatter.format(value);
  }

  /// تنسيق نسبة مئوية - Percentage format
  /// مثال: 85.5%
  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// تنسيق الساعات - Hours format
  /// مثال: 8.5 ساعة
  static String hours(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()} ساعة';
    }
    return '${value.toStringAsFixed(1)} ساعة';
  }

  /// تنسيق الكمية - Quantity format
  /// مثال: 25 وحدة
  static String quantity(int value, {String unit = 'وحدة'}) {
    return '${format(value)} $unit';
  }
}
