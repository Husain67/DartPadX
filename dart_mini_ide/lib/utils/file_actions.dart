import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileActions {
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(msg: 'Copied to clipboard');
  }

  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  static Future<void> downloadFile(String name, String content) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading file');
    }
  }

  static Future<void> shareAsDeepLink(String content) async {
    final bytes = utf8.encode(content);
    final base64Str = base64UrlEncode(bytes);
    final link = 'https://dartmini.ide/?code=$base64Str';
    await Share.share(link);
  }

  static Future<String?> importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error importing file');
    }
    return null;
  }
}
