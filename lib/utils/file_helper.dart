import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/providers.dart';

class FileHelper {
  static Future<void> importFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final name = result.files.single.name;
        ref.read(fileProvider.notifier).addFile(name, content);
        Fluttertoast.showToast(msg: "Imported $name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  static void copyActiveFile(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Copied to clipboard");
    }
  }

  static Future<void> pasteToActiveFile(WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final notifier = ref.read(fileProvider.notifier);
      final currentContent = ref.read(fileProvider).activeFile?.content ?? '';
      notifier.updateActiveFileContent(currentContent + data.text!);
      notifier.forceUpdate(); // force rebuild to sync editor
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  static Future<void> downloadActiveFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
             dir = await getExternalStorageDirectory();
          }
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        if (dir != null) {
          final file = File('${dir.path}/${activeFile.name}');
          await file.writeAsString(activeFile.content);
          Fluttertoast.showToast(msg: "Saved to: ${file.path}");
        } else {
          Fluttertoast.showToast(msg: "Could not access storage directory");
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Download failed: $e");
      }
    }
  }

  static Future<void> shareActiveFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      final fakeDeepLink = "dartmini://code?data=$base64Code";
      final _ = await Share.share("Check out my Dart code on DartMini IDE:\n\n$fakeDeepLink");
    }
  }
}
