import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> shareText(String text, String subject) async {
    await Share.share(text, subject: subject);
  }

  static Future<void> downloadFile(String filename, String content) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      // Use shareXFiles to give the user a way to actually save it or send it somewhere
      // since pure downloading to public directories is complex on mobile without specific plugins.
      await Share.shareXFiles([XFile(file.path)], subject: 'Download $filename');
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
}
