import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class Utils {
  static String encodeBasicAuth(String username, String password) {
    String credentials = '$username:$password';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    return stringToBase64.encode(credentials);
  }

  static dynamic extractJsonPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;

    List<String> keys = path.split('.');
    dynamic current = json;

    for (String key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current;
  }
}
