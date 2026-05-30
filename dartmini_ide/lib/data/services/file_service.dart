import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  static Future<String?> importDartFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      return await file.readAsString();
    }
    return null;
  }

  static Future<String?> downloadDartFile(String name, String content) async {
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
        final path = '${directory.path}/$name';
        final file = File(path);
        await file.writeAsString(content);
        return path;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<void> shareCode(String content) async {
    await Share.share(content);
  }
}
