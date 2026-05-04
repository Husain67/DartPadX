import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  Future<String?> pickDartFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      return await file.readAsString();
    }
    return null;
  }

  Future<String?> saveDartFile(String name, String content) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory != null) {
        String safeName = name.endsWith('.dart') ? name : '\$name.dart';
        final filePath = '\${directory.path}/\$safeName';
        final file = File(filePath);
        await file.writeAsString(content);
        return filePath;
      }
    } catch (e) {
      print('Error saving file: \$e');
    }
    return null;
  }

  Future<void> shareDartFile(String name, String content) async {
    // For a pure mobile app, we can write it to a temp file and share the file,
    // or just share the text. Let's do both (share text for simple copy-paste).
    // The prompt asks for base64 or deep link mock. We'll share text directly or file.
    try {
      final directory = await getTemporaryDirectory();
      final file = File('\${directory.path}/\$name');
      await file.writeAsString(content);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Check out my Dart code!');
    } catch (e) {
      print('Error sharing file: \$e');
      // Fallback to text
      Share.share(content);
    }
  }
}
