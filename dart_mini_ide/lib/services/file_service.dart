import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String?> pickAndReadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        return String.fromCharCodes(result.files.single.bytes!);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<bool> saveFileMobile(String fileName, String content) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Fallback to downloads if possible, simplified for now
        final String path = '/storage/emulated/0/Download';
        final dir = Directory(path);
        if (await dir.exists()) {
           directory = dir;
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final File file = File('${directory.path}/$fileName');
        await file.writeAsString(content);
        return true;
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }
}
