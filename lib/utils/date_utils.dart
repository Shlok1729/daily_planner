import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format a date to a readable string (e.g., "Monday, January 1, 2023")
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Format a date to a short string (e.g., "Jan 1, 2023")
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format a date to show only the day of week (e.g., "Monday")
  static String formatDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Format a date to show only the month and day (e.g., "January 1")
  static String formatMonthDay(DateTime date) {
    return DateFormat('MMMM d').format(date);
  }

  /// Format a time (e.g., "3:30 PM")
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format a time in 24-hour format (e.g., "15:30")
  static String formatTime24Hour(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Get a relative time string (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ${difference.isNegative ? 'ago' : 'from now'}';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ${difference.isNegative ? 'ago' : 'from now'}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ${difference.isNegative ? 'ago' : 'from now'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ${difference.isNegative ? 'ago' : 'from now'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ${difference.isNegative ? 'ago' : 'from now'}';
    } else {
      return 'Just now';
    }
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// Get the start of the day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of the day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get the start of the week (Sunday)
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  /// Get the end of the week (Saturday)
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date).add(Duration(days: 6));
  }

  /// Get the start of the month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the end of the month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get a list of dates for a week
  static List<DateTime> getDatesInWeek(DateTime date) {
    final startDate = startOfWeek(date);
    return List.generate(7, (index) => startDate.add(Duration(days: index)));
  }

  /// Get a list of dates for a month
  static List<DateTime> getDatesInMonth(DateTime date) {
    final startDate = startOfMonth(date);
    final endDate = endOfMonth(date);
    final daysInMonth = endDate.day;

    return List.generate(
      daysInMonth,
          (index) => DateTime(date.year, date.month, index + 1),
    );
  }
}