import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  static Future<String?> downloadFile(String name, String content) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('\${directory.path}/\$name');
        await file.writeAsString(content);
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> shareCode(String name, String content) async {




    final b64 = base64Encode(utf8.encode(content));
    final link = 'dartmini://share?name=$name&code=$b64';
    await Share.share('Check out my Dart code on DartMini IDE!\n\n$link');
  }
}
