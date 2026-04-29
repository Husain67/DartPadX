import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FileOps {
  static Future<String?> importDartFile() async {
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
      Fluttertoast.showToast(msg: "Failed to import file");
    }
    return null;
  }

  static Future<void> downloadDartFile(String filename, String content) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        String path = "${directory.path}/$filename";
        File file = File(path);
        await file.writeAsString(content);
        Fluttertoast.showToast(msg: "Downloaded to: $path");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to download file");
    }
  }

  static Future<void> shareCode(String content) async {
    try {
      String base64Code = base64Encode(utf8.encode(content));
      String mockDeepLink = "dartmini://code?data=$base64Code";
      await Share.share("Check out my Dart code on DartMini IDE:\n$mockDeepLink");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to share code");
    }
  }

  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  static Future<String?> pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      return data.text;
    }
    Fluttertoast.showToast(msg: "Nothing to paste");
    return null;
  }
}
