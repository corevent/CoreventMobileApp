import 'package:flutter/services.dart';

String phoneDigits(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('55') && (digits.length == 12 || digits.length == 13)) {
    digits = digits.substring(2);
  }
  return digits;
}

String normalizePhone(String value) {
  final digits = phoneDigits(value);
  return digits.isEmpty ? '' : '+55$digits';
}

String formatPhone(String value) {
  final digits = phoneDigits(value);
  if (digits.isEmpty) return '';
  if (digits.length > 11) return value;
  if (digits.length <= 2) return '($digits';
  final number = digits.substring(2);
  final prefix = number.length > 8 ? 5 : 4;
  if (number.length <= prefix) return '(${digits.substring(0, 2)}) $number';
  return '(${digits.substring(0, 2)}) ${number.substring(0, prefix)}-${number.substring(prefix)}';
}

String formatDocument(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  if (digits.length == 14) {
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }
  return value?.isNotEmpty == true ? value! : 'Não informado';
}

class BrazilianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = phoneDigits(newValue.text);
    if (digits.length > 11) return oldValue;
    final formatted = formatPhone(digits);
    final beforeCaret = newValue.text
        .substring(
          0,
          newValue.selection.extentOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var seen = 0;
    var caret = formatted.length;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) seen++;
      if (seen == beforeCaret) {
        caret = i + 1;
        break;
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}
