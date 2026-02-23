import 'package:intl/intl.dart';

class AppUtils {
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date);
  }
}
