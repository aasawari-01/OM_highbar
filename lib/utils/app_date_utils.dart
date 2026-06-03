import 'package:intl/intl.dart';

class AppDateUtils {
  static const String datePattern = 'dd/MM/yyyy';
  static const String timePattern = 'hh:mm a';
  static const String dateTimePattern = 'dd/MM/yyyy, hh:mm a';
  static const String monthYearPattern = 'MMMM/yyyy';
  static const String shortMonthPattern = 'MMM';

  static String formatDate(DateTime date) => DateFormat(datePattern).format(date);
  static String formatTime(DateTime date) => DateFormat(timePattern).format(date);
  static String formatDateTime(DateTime date) => DateFormat(dateTimePattern).format(date);
  static String formatMonthYear(DateTime date) => DateFormat(monthYearPattern).format(date);
  static String formatShortMonth(DateTime date) => DateFormat(shortMonthPattern).format(date);


  static String? parseFromServer(String? serverDate) {
    if (serverDate == null || serverDate.isEmpty) return null;
    try {
      DateTime dt = DateTime.parse(serverDate);
      return formatDate(dt);
    } catch (_) {
      return serverDate;
    }
  }

  static String formatToApiDate(String localDate) {
    if (localDate.isEmpty) return localDate;
    final parts = localDate.replaceAll('/', ' ').replaceAll('-', ' ').trim().split(' ');
    if (parts.length != 3) return localDate;
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  static DateTime? parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateFormat(datePattern).parse(dateStr);
    } catch (_) {
      // Fallback: try ISO format
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  static DateTime? parseTime(String timeStr) {
    if (timeStr.isEmpty) return null;
    try {
      final now = DateTime.now();
      final dt = DateFormat(timePattern).parse(timeStr);
      return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
    } catch (_) {
      return null;
    }
  }

}
