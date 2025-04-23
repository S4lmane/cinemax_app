import 'package:intl/intl.dart';

class DateFormatter {
  // Format date to yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format date to full date (e.g. January 1, 2023)
  static String formatFullDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // Format date to MMM d, yyyy (e.g. Jan 1, 2023)
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Parse date string from API (yyyy-MM-dd)
  static DateTime? parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Get year from date string
  static String getYear(String dateStr) {
    if (dateStr.isEmpty) return '';

    final date = parseDate(dateStr);
    if (date == null) return '';

    return DateFormat('yyyy').format(date);
  }

  // Get formatted release date (e.g. "Released Jan 1, 2023")
  static String getFormattedReleaseDate(String dateStr) {
    if (dateStr.isEmpty) return 'Release date unknown';

    final date = parseDate(dateStr);
    if (date == null) return 'Release date unknown';

    final now = DateTime.now();

    if (date.isAfter(now)) {
      return 'Coming on ${formatShortDate(date)}';
    } else {
      return 'Released ${formatShortDate(date)}';
    }
  }

  // Get time ago string
  static String getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  // Format minutes to hours and minutes
  static String formatRuntime(int minutes) {
    if (minutes <= 0) return '';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }
}