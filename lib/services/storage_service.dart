import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StorageService {
  Future<Map<String, String>?> pickDartFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        return {
          'name': result.files.single.name,
          'content': content,
        };
      }
    } catch (e) {
      // Handle error gracefully
      // ignore: avoid_print
      print('Error picking file: $e');
    }
    return null;
  }

  Future<String?> downloadFile(String fileName, String content) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      // ignore: avoid_print
      print('Error downloading file: $e');
      return null;
    }
  }

  Future<void> shareCodeAsDeepLink(String code) async {
    final b64 = base64Encode(utf8.encode(code));
    final String link = 'dartmini://share?code=$b64';
    await Share.share(link, subject: 'DartMini Code Snippet');
  }
}
