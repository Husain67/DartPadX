import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dartmini_ide/src/features/editor/domain/file_model.dart';

class FileActions {
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      return data!.text;
    }
    Fluttertoast.showToast(msg: "Clipboard is empty");
    return null;
  }

  static Future<Map<String, String>?> importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      return {'name': result.files.single.name, 'content': content};
    }
    return null;
  }

  static Future<void> downloadFile(FileModel file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetPath = '${directory.path}/${file.name}';
      final newFile = File(targetPath);
      await newFile.writeAsString(file.content);
      Fluttertoast.showToast(msg: "Saved to ${newFile.path}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving file: $e");
    }
  }

  static Future<void> shareFile(FileModel file) async {
    await Share.share(file.content, subject: file.name);
  }
}
