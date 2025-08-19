import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageServices {
  /// Uploads an image file to Firebase Storage
  ///
  /// Parameters:
  ///   imageFile: The XFile image to be uploaded
  ///
  /// Returns:
  ///   A Future<String> containing the full storage path of the uploaded file
  ///
  /// Throws:
  ///   Exception if the upload fails
  Future<String> uploadImage(XFile imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final bytes = await imageFile.readAsBytes();
      final uploadTask = await storageRef.putData(bytes);

      // final downloadUrl = await storageRef.getDownloadURL();//
      print('Upload successful!');
      return uploadTask.ref.fullPath;
    } catch (e) {
      print('Upload failed: $e');
      throw Exception('Image upload failed: $e');
    }
  }
}
