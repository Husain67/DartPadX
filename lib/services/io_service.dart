import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class IOService {
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: 'Copied to clipboard',
      backgroundColor: const Color(0xFFFACC15),
      textColor: Colors.black,
    );
  }

  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  static Future<void> shareCode(String code) async {
    if (code.isEmpty) return;
    await Share.share(code, subject: 'Dart Code Snippet');
  }

  static Future<void> downloadFile(String name, String content) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Or getExternalStorageDirectories(type: StorageDirectory.downloads)
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/$name');
        await file.writeAsString(content);
        Fluttertoast.showToast(
          msg: 'File saved to ${file.path}',
          backgroundColor: const Color(0xFFFACC15),
          textColor: Colors.black,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to save file: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  static Future<Map<String, String>?> importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.first;
        if (platformFile.bytes != null) {
          final content = String.fromCharCodes(platformFile.bytes!);
          return {'name': platformFile.name, 'content': content};
        } else if (platformFile.path != null) {
          final file = File(platformFile.path!);
          final content = await file.readAsString();
          return {'name': platformFile.name, 'content': content};
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to import file: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    return null;
  }
}
