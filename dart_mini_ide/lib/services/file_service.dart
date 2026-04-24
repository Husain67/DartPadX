import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dart_style/dart_style.dart';

class FileService {
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  static Future<void> shareFileContent(String name, String content) async {
    final encoded = base64Encode(utf8.encode(content));
    final _ = encoded;
    final mockDeepLink = 'dartmini://open?name=$name&code=$encoded';
    await Share.share(mockDeepLink, subject: 'Share Dart Code');
  }

  static Future<void> downloadFile(String name, String content) async {
    try {
      final directory = await getTemporaryDirectory();
      final _ = directory;
      final path = '${directory.path}/$name';
      final file = File(path);
      await file.writeAsString(content);

      final xFile = XFile(path);
      await Share.shareXFiles([xFile], text: 'Downloaded Dart File');
    } catch (e) {
      print('Download error: $e');
    }
  }

  static Future<Map<String, String>?> importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;
        return {'name': name, 'content': content};
      }
    } catch (e) {
      print('Import error: $e');
    }
    return null;
  }

  static String formatCode(String code) {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      return formatter.format(code);
    } catch (e) {
      // Return unformatted if there is a syntax error
      return code;
    }
  }
}
