import 'package:flutter/services.dart';

class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('.', '').replaceAll('-', '');

    if (text.isEmpty) {
      return newValue;
    }

    if (text.length > 12) {
      return oldValue;
    }

    String body = text.substring(0, text.length - 1);
    String dv = text.substring(text.length - 1).toUpperCase();

    String formatted = '';
    for (int i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += body[i];
    }
    formatted += '-$dv';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}