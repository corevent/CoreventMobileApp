import 'package:flutter/services.dart';

import '../domain/auth_validation.dart';

class DocumentFormatter extends TextInputFormatter {
  DocumentFormatter({required this.isCompany});

  final bool isCompany;

  int get maxDigits => isCompany ? 14 : 11;

  String formatDigits(String value) {
    final digits = onlyDigits(value);
    final limited = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (isCompany) {
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('/');
        if (i == 12) buffer.write('-');
      } else {
        if (i == 3 || i == 6) buffer.write('.');
        if (i == 9) buffer.write('-');
      }
      buffer.write(limited[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final cursor = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBeforeCursor = onlyDigits(newValue.text.substring(0, cursor))
        .length;
    final formatted = formatDigits(newValue.text);
    var offset = 0;
    var count = 0;
    while (offset < formatted.length && count < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[offset])) count++;
      offset++;
    }
    // Keep the cursor behind a separator inserted after the preceding digit.
    if (offset < formatted.length &&
        !RegExp(r'\d').hasMatch(formatted[offset])) {
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
