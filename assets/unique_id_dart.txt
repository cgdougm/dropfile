import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Unique identifier for an XFile
extension UniqueXFile on XFile {
  String get uniqueId => sha256.convert(utf8.encode(path)).toString();
  ValueKey get key => ValueKey(uniqueId);
}

/// Unique identifier for a URI
extension UniqueURL on Uri {
  String get uniqueId => sha256.convert(utf8.encode(toString())).toString();
  ValueKey get key => ValueKey(uniqueId);
}
