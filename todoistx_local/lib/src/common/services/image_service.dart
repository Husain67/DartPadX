import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Pick an image from gallery or camera and save it to a local directory.
  // Returns the local file path of the saved image.
  // (गैलरी या कैमरे से एक छवि चुनें और उसे एक स्थानीय निर्देशिका में सहेजें।
  // सहेजी गई छवि का स्थानीय फ़ाइल पथ लौटाता है।)
  Future<String?> pickAndSaveImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) {
        return null; // User canceled the picker
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}${p.extension(pickedFile.path)}';
      final localImagePath = p.join(appDir.path, 'images', fileName);

      // Ensure the directory exists
      final imageDir = Directory(p.join(appDir.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Copy the file to the new path
      final File imageFile = File(pickedFile.path);
      await imageFile.copy(localImagePath);

      return localImagePath;
    } catch (e) {
      // Handle exceptions
      print('Error picking and saving image: $e');
      return null;
    }
  }
}
