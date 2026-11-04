import 'dart:convert';

import '../domain/models.dart';

/// Decodes an object without leaking malformed response content in an error.
Map<String, dynamic> decodeJsonObject(String source) {
  try {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) throw const ParseFailure('json');
    return value;
  } on FormatException {
    throw const ParseFailure('json');
  }
}
