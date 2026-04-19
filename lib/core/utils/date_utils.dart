import 'package:intl/intl.dart';

/// أدوات التاريخ - Date Utilities
/// دوال مساعدة للتعامل مع التواريخ بالعربية والإنجليزية
class AppDateUtils {
  AppDateUtils._();

  /// تنسيق التاريخ بالعربية - Arabic date format
  /// مثال: ١٩ أبريل ٢٠٢٦
  static String formatArabic(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  /// تنسيق التاريخ المختصر - Short date format
  /// مثال: ١٩/٤/٢٠٢٦
  static String formatShort(DateTime date) {
    return DateFormat('d/M/yyyy', 'ar').format(date);
  }

  /// تنسيق التاريخ والوقت - Date and time format
  /// مثال: ١٩ أبريل ٢٠٢٦ - ٠٢:٣٠ م
  static String formatWithTime(DateTime date) {
    return DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(date);
  }

  /// تنسيق الوقت فقط - Time only
  /// مثال: ٠٢:٣٠ م
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  /// تنسيق ISO للتخزين - Storage format (ISO 8601)
  static String toIso(DateTime date) {
    return date.toIso8601String();
  }

  /// من ISO إلى DateTime
  static DateTime? fromIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  /// تنسيق التاريخ للعرض في الجدول - Table display format
  /// مثال: 2026-04-19
  static String formatForTable(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// تنسيق تاريخ اليوم بالنص - Today string (for queries)
  /// مثال: 2026-04-19
  static String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// بداية اليوم - Start of day
  static DateTime startOfDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  /// نهاية اليوم - End of day
  static DateTime endOfDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  /// بداية الشهر - Start of month
  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, 1);
  }

  /// نهاية الشهر - End of month
  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59);
  }

  /// حساب الفرق بالساعات بين وقتين - Hours difference
  static double hoursBetween(DateTime start, DateTime end) {
    return end.difference(start).inMinutes / 60.0;
  }

  /// هل التاريخ اليوم؟ - Is today?
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// منذ متى (نص نسبي) - Relative time text
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    if (diff.inDays < 30) return 'منذ ${diff.inDays ~/ 7} أسبوع';
    return formatShort(date);
  }
}
