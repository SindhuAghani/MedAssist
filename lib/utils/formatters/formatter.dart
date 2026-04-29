import 'package:intl/intl.dart';

/// A utility class for formatting various types of data such as dates,
/// currency, and phone numbers.
class TFormatter {
  /// Formats a DateTime object to a string in the format 'dd/MM/yyyy'.
  /// If no date is provided, it defaults to the current date.
  static String formatDate(DateTime? date) {
    date ??= DateTime.now(); // Use current date if no date is provided.
    final onlyDate = DateFormat('dd/MM/yyyy').format(date); // Format the date.
    return onlyDate;
  }

  /// Formats a DateTime object to a string in the format 'dd/MM/yyyy at hh:mm'.
  /// If no date is provided, it defaults to the current date and time.
  static String formatDateAndTime(DateTime? date) {
    date ??= DateTime.now(); // Use current date and time if no date is provided.
    final onlyDate = DateFormat('dd/MM/yyyy').format(date); // Format the date.
    final onlyTime = DateFormat('hh:mm').format(date); // Format the time.
    return '$onlyDate at $onlyTime'; // Combine date and time.
  }

  /// Formats a numeric amount as currency in USD (default locale: en_US, symbol: $).
  /// You can customize the locale and symbol if needed.
  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
    // Customize the currency locale and symbol as needed.
  }

  /// Formats a 10 or 11-digit phone number into a human-readable format.
  /// Example (1234567890) becomes (123) 456-7890.
  static String formatPhoneNumber(String phoneNumber) {
    // Check if the phone number has 10 or 11 digits
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
    } else if (phoneNumber.length == 11) {
      return '(${phoneNumber.substring(0, 4)}) ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    // If the format is not recognized, return the phone number as is.
    return phoneNumber;
  }

  /// Formats a phone number into an international format.
  /// Removes non-digit characters and adds the country code with proper spacing.
  /// Example: '+11234567890' becomes (+1) 123 45 67 890.
  static String internationalFormatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters from the phone number
    var digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Extract the country code from the digitsOnly
    String countryCode = '+${digitsOnly.substring(0, 2)}';
    digitsOnly = digitsOnly.substring(2); // Remove country code from the number.

    // Add the remaining digits with proper formatting.
    final formattedNumber = StringBuffer();
    formattedNumber.write('($countryCode) ');

    int i = 0;
    while (i < digitsOnly.length) {
      int groupLength = 2; // Default group length for international phone numbers.
      if (i == 0 && countryCode == '+1') {
        groupLength = 3; // Special case for US: first group of 3 digits.
      }

      int end = i + groupLength;
      formattedNumber.write(digitsOnly.substring(i, end)); // Add the group.

      if (end < digitsOnly.length) {
        formattedNumber.write(' '); // Add space between groups.
      }
      i = end; // Move to the next group.
    }

    return formattedNumber.toString(); // Return the formatted phone number.
  }

  /// Concatenate phone number and country code
  static String formatPhoneNumberWithCountryCode(String countryCode, String phoneNumber) {
    // Remove leading zero if present
    // if (phoneNumber.startsWith('0')) {
    //   phoneNumber = phoneNumber.substring(1);
    // }

    // Combine country code and phone number
    return '$countryCode$phoneNumber';
  }
}
