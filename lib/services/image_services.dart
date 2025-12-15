import 'package:image_picker/image_picker.dart';

/// Service for handling image-related operations.
/// Provides methods for picking images from gallery or camera.
///
/// Example usage:
/// ```dart
/// final imageServices = ImageServices();
/// final image = await imageServices.pickImage(ImageSource.gallery);
/// ```
class ImageServices {
  /// Internal image picker instance
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the specified source (gallery or camera).
  ///
  /// Returns an [XFile] if successful, null if picking was cancelled or failed.
  /// Errors are caught and logged, returning null instead of throwing.
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source);
    } catch (e) {
      print('Error picking image from $source: $e');
      return null;
    }
  }

  /// Picks multiple images from the gallery.
  ///
  /// Returns a list of [XFile] if successful, empty list if picking was cancelled or failed.
  /// Errors are caught and logged, returning empty list instead of throwing.
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final images = await _picker.pickMultiImage();
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
}
