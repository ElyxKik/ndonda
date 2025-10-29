import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService instance = ImageService._init();
  final ImagePicker _picker = ImagePicker();

  ImageService._init();

  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<List<String>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      List<String> savedPaths = [];
      for (var image in images) {
        final savedPath = await _saveImage(image);
        if (savedPath != null) {
          savedPaths.add(savedPath);
        }
      }
      return savedPaths;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  Future<String?> _saveImage(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'images');
      
      // Create images directory if it doesn't exist
      await Directory(imagesDir).create(recursive: true);

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final String savedPath = path.join(imagesDir, fileName);

      await File(image.path).copy(savedPath);
      return savedPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  Future<void> deleteMultipleImages(List<String> imagePaths) async {
    for (var imagePath in imagePaths) {
      await deleteImage(imagePath);
    }
  }
}
