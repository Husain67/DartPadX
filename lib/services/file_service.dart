import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  static Future<String?> importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        return await file.readAsString();
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  static Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> downloadFile(String name, String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedName = name.endsWith('.dart') ? name : '$name.dart';
      final file = File('${directory.path}/$sanitizedName');
      await file.writeAsString(content);

      // Attempt to save to downloads or general storage (implementation varies heavily by platform,
      // but for basic sharing/saving, saving to docs and letting the user access is baseline)
      // Usually requires extra native code, but we will return success if written to app storage.
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> shareFile(String name, String content) async {
    try {
      // Share as text if small, or temp file if needed. We'll share raw code for IDE style.
      await Share.share(content, subject: 'Dart Code: $name');
    } catch (e) {
      // Ignore
    }
  }
}
