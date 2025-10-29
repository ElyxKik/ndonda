import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatDateLong(DateTime date) {
    return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
  }

  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime getEndOfWeek(DateTime date) {
    return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static DateTime getStartOfSemester(DateTime date) {
    int semester = date.month <= 6 ? 1 : 2;
    int startMonth = semester == 1 ? 1 : 7;
    return DateTime(date.year, startMonth, 1);
  }

  static DateTime getEndOfSemester(DateTime date) {
    int semester = date.month <= 6 ? 1 : 2;
    int endMonth = semester == 1 ? 6 : 12;
    return DateTime(date.year, endMonth + 1, 0);
  }

  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  static Map<String, DateTime> getDateRange(String reportType, DateTime referenceDate) {
    DateTime startDate;
    DateTime endDate;

    switch (reportType) {
      case 'Hebdomadaire':
        startDate = getStartOfWeek(referenceDate);
        endDate = getEndOfWeek(referenceDate);
        break;
      case 'Mensuel':
        startDate = getStartOfMonth(referenceDate);
        endDate = getEndOfMonth(referenceDate);
        break;
      case 'Semestriel':
        startDate = getStartOfSemester(referenceDate);
        endDate = getEndOfSemester(referenceDate);
        break;
      case 'Annuel':
        startDate = getStartOfYear(referenceDate);
        endDate = getEndOfYear(referenceDate);
        break;
      default:
        startDate = getStartOfMonth(referenceDate);
        endDate = getEndOfMonth(referenceDate);
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  static String getDateRangeLabel(String reportType, DateTime referenceDate) {
    final range = getDateRange(reportType, referenceDate);
    final start = formatDate(range['startDate']!);
    final end = formatDate(range['endDate']!);
    return '$start - $end';
  }
}
