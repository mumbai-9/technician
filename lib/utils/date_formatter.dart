import 'package:intl/intl.dart';

class DateFormatter {
  /// Format date to DD/MM/YYYY
  static String formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Format datetime to DD/MM/YYYY HH:mm
  static String formatDateTime(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Format datetime to DD/MM/YYYY HH:mm:ss
  static String formatDateTimeWithSeconds(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Format date to DD/MM/YYYY with month name (e.g., 09 Mar 2026)
  static String formatDateWithMonthName(dynamic date, {bool short = true}) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      final format = short ? 'dd MMM yyyy' : 'dd MMMM yyyy';
      return DateFormat(format).format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Format time to HH:mm (24-hour format)
  static String formatTime24(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Format time to hh:mm a (12-hour format with AM/PM)
  static String formatTime12(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// Parse DD/MM/YYYY to yyyy-MM-dd for API/database
  static String? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // If already in yyyy-MM-dd format, return as is
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return dateStr;
      }

      // Parse DD/MM/YYYY format
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      // Try standard parsing as fallback
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('yyyy-MM-dd').format(date);
      } catch (e2) {
        return null;
      }
    }
  }

  /// Get current date in DD/MM/YYYY format
  static String getCurrentDate() {
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  /// Get current date in yyyy-MM-dd format (for API)
  static String getCurrentDateForApi() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Get current datetime in DD/MM/YYYY HH:mm format
  static String getCurrentDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  }
}
