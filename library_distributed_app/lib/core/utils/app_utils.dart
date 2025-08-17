import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Format date to Vietnamese format
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _dateFormat.format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Format datetime to Vietnamese format
  static String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return _dateTimeFormat.format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Check if date string is overdue
  static bool isOverdue(String dueDateString) {
    try {
      final dueDate = DateTime.parse(dueDateString);
      return dueDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Calculate days between two dates
  static int daysBetween(String fromDateString, String toDateString) {
    try {
      final fromDate = DateTime.parse(fromDateString);
      final toDate = DateTime.parse(toDateString);
      return toDate.difference(fromDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate days from date to now
  static int daysFromNow(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateTime.now().difference(date).inDays;
    } catch (e) {
      return 0;
    }
  }
}
