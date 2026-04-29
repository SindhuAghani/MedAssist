import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';

class THelperFunctions {
  static Color? getColor(String value) {
    /// Define your product specific colors here and it will match the attribute colors and show specific 🟠🟡🟢🔵🟣🟤

    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else if (value == 'Orange') {
      return Colors.deepOrange;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else {
      return null;
    }
  }

  /// Restore a [Color] from a 32-bit ARGB integer value.
  static Color restoreColorFromValue(String value) {
    final intValue = int.tryParse(value) ?? 0;
    final a = (intValue >> 24) & 0xFF; // Extract alpha
    final r = (intValue >> 16) & 0xFF; // Extract red
    final g = (intValue >> 8) & 0xFF; // Extract green
    final b = intValue & 0xFF; // Extract blue

    // Create the color with values in the 0-255 range and alpha in 0-255.
    return Color.fromARGB(a, r, g, b);
  }

  static void showSnackBar(String message) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Convert a [Color] to its 32-bit ARGB integer value.
  static int computeColorValue(Color color) {
    final a = (color.a * 255).round(); // Convert alpha to 0-255
    final r = (color.r * 255).round(); // Convert red to 0-255
    final g = (color.g * 255).round(); // Convert green to 0-255
    final b = (color.b * 255).round(); // Convert blue to 0-255

    // Combine ARGB into a single 32-bit integer
    final intValue = (a << 24) | (r << 16) | (g << 8) | b;
    return intValue;
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static String getFormattedDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(i, i + rowSize > widgets.length ? widgets.length : i + rowSize);
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  static String maskPhoneNumber(String number) {
    if (number.length > 6) {
      final visibleStart = number.substring(0, 2);
      final visibleEnd = number.substring(number.length - 3);
      final maskedPart = '*' * (number.length - visibleStart.length - visibleEnd.length);
      return '$visibleStart $maskedPart $visibleEnd';
    }
    return number;
  }

  /// Date comparison helper
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get first day of month
  DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get last day of month
  DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Format time string
  String formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
        return '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      return time;
    }
    return time;
  }

  /// Check if time is in range
  bool isTimeInRange(String time, String start, String end) {
    try {
      final timeParts = time.split(':');
      final startParts = start.split(':');
      final endParts = end.split(':');

      if (timeParts.length == 2 && startParts.length == 2 && endParts.length == 2) {
        final timeValue = int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]);
        final startValue = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endValue = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        return timeValue >= startValue && timeValue <= endValue;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Get medication status
  String getMedicationStatus(Medication medication, DateTime selectedDate) {
    final now = DateTime.now();

    if (selectedDate.isAfter(now)) {
      return 'Upcoming';
    }

    if (medication.endDate != null && selectedDate.isAfter(medication.endDate!)) {
      return 'Completed';
    }

    return 'Active';
  }
}
