import 'package:dart_style/dart_style.dart';

class FormatUtils {
  static String formatDartCode(String code) {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      return formatter.format(code);
    } catch (e) {
      // If code contains syntax errors, formatter throws. We just return original.
      return code;
    }
  }
}
