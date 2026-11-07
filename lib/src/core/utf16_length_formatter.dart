import 'package:flutter/services.dart';

/// Matches server string limits without cutting a surrogate pair in half.
class Utf16LengthFormatter extends TextInputFormatter {
  Utf16LengthFormatter(this.limit) : assert(limit > 0);
  final int limit;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= limit || !newValue.composing.isCollapsed) {
      return newValue;
    }
    var end = limit;
    final last = newValue.text.codeUnitAt(end - 1);
    if (last >= 0xD800 && last <= 0xDBFF) end--;
    return newValue.copyWith(
      text: newValue.text.substring(0, end),
      selection: TextSelection(
        baseOffset: newValue.selection.baseOffset.clamp(0, end),
        extentOffset: newValue.selection.extentOffset.clamp(0, end),
      ),
      composing: TextRange.empty,
    );
  }
}
