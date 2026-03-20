import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat("#,###");

  /// Formats a double into a string with thousand separators (e.g., 1000 -> 1,000)
  static String format(double? value) {
    if (value == null) return "0";
    return _formatter.format(value);
  }

  /// Strips commas and parses a string into a double
  static double parse(String? value) {
    if (value == null || value.isEmpty) return 0.0;
    final cleaned = value.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// A TextInputFormatter for real-time comma separation as the user types
  static TextInputFormatter get inputFormatter => ThousandsSeparatorInputFormatter();
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) return newValue;

    final double? value = double.tryParse(newValue.text.replaceAll(',', ''));
    if (value == null) return oldValue;

    final formatter = NumberFormat("#,###");
    final String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
