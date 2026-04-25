import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/code_file.dart';

class FileService {
  static Future<String?> importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        return content;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import file");
    }
    return null;
  }

  static Future<void> downloadFile(CodeFile file) async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${file.name}';
      final fileIo = File(path);
      await fileIo.writeAsString(file.content);

      await Share.shareXFiles([XFile(path)], text: 'Download ${file.name}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to download file");
    }
  }

  static Future<void> shareCode(CodeFile file) async {
    try {
      String base64Code = base64Encode(utf8.encode(file.content));
      String shareText = 'Check out my code: \n\n${file.name}\n\nBase64:\n$base64Code';
      await Share.share(shareText, subject: 'DartMini Code: ${file.name}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to share code");
    }
  }
}
