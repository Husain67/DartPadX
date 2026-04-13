import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../models/code_file.dart';

class EditorActions {
  static void newFile(WidgetRef ref) {
    ref.read(fileProvider.notifier).newFile();
  }

  static Future<void> importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final codeFile = CodeFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result.files.single.name,
        content: content,
      );
      ref.read(fileProvider.notifier).addFile(codeFile);
    }
  }

  static Future<void> copyCode(String? content) async {
    if (content == null || content.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: content));
    Fluttertoast.showToast(
      msg: 'Code copied to clipboard',
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
    );
  }

  static Future<void> pasteCode(CodeController controller) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final text = data!.text!;
      final selection = controller.selection;
      if (selection.isValid) {
        final newText = controller.text.replaceRange(selection.start, selection.end, text);
        controller.value = controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start + text.length),
        );
      } else {
        controller.text += text;
      }
    }
  }

  static Future<void> downloadFile(CodeFile? file) async {
    if (file == null) return;
    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/${file.name}');
    await tempFile.writeAsString(file.content);
    await Share.shareXFiles([XFile(tempFile.path)], text: 'Download ${file.name}');
  }

  static Future<void> shareFile(CodeFile? file) async {
    if (file == null) return;
    final base64Content = base64Encode(utf8.encode(file.content));
    final mockLink = 'dartmini://share?code=$base64Content';
    await Share.share('Check out my Dart code on DartMini IDE:\n\n$mockLink');
  }

  static Future<void> deleteFile(BuildContext context, WidgetRef ref, String? fileId) async {
    if (fileId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: const Text('Delete this file? This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteFile(fileId);
      Fluttertoast.showToast(
        msg: 'File deleted',
        backgroundColor: Colors.grey[800],
        textColor: Colors.white,
      );
    }
  }

  static void formatCode(CodeController controller) {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(controller.text);
      controller.text = formatted;
      Fluttertoast.showToast(
        msg: 'Code formatted',
        backgroundColor: Colors.grey[800],
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Formatting failed: Syntax error',
        backgroundColor: Colors.red[800],
        textColor: Colors.white,
      );
    }
  }
}
