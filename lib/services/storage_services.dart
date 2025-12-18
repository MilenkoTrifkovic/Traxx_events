import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/models/event.dart';

class StorageServices {
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
      rethrow;
    }
  }

  Future<Event> loadImage(Event event) async {
    try {
      String? path = event.coverImageUrl;
      if (path == null || path.isEmpty) {
        return event;
      }
      final ref = FirebaseStorage.instance.ref().child(path);
      event.coverImageDownloadUrl = await ref.getDownloadURL();
      print('image loaded for event ${event.eventId}');
      print(' url: ${event.coverImageDownloadUrl}');
    } catch (e) {
      print('Image loading failed: $e');
    }
    return event;
  }

  Future<String?> loadImageURL(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Image loading failed: $e');
      return null; // or throw
    }
  }
}
