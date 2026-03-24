import 'package:dart_style/dart_style.dart';

class FormatUtils {
  static String formatDartCode(String code) {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      return formatter.format(code);
    } catch (e) {
      // Return original code if formatting fails due to syntax errors
      return code;
    }
  }
}
