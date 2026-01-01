import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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

  /// Uploads an invitation letter file (PDF or image) to Firebase Storage
  /// 
  /// Parameters:
  /// - [file]: The PlatformFile from file picker
  /// - [eventId]: The event ID to organize files
  /// 
  /// Returns a Map with 'path' and 'downloadUrl'
  /// Throws exception on upload failure
  Future<Map<String, String>> uploadInvitationLetter(
    PlatformFile file,
    String eventId,
  ) async {
    try {
      if (file.bytes == null) {
        throw Exception('File bytes are null. Cannot upload.');
      }

      // Determine content type based on file extension
      String contentType;
      final extension = file.extension?.toLowerCase();
      switch (extension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      // Create storage path: invitation_letters/eventId/timestamp_filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'invitation_letters/$eventId/${timestamp}_${file.name}';

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Upload file with metadata
      await storageRef.putData(
        file.bytes!,
        SettableMetadata(contentType: contentType),
      );

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      print('Invitation letter uploaded successfully');
      print('Path: $storagePath');
      print('Download URL: $downloadUrl');

      return {
        'path': storagePath,
        'downloadUrl': downloadUrl,
      };
    } catch (e) {
      print('Failed to upload invitation letter: $e');
      rethrow;
    }
  }

  /// Deletes an invitation letter file from Firebase Storage
  /// 
  /// Parameters:
  /// - [path]: The storage path of the file to delete
  /// 
  /// Returns true if deletion was successful
  Future<bool> deleteInvitationLetter(String path) async {
    try {
      if (path.isEmpty) {
        print('No path provided for deletion');
        return false;
      }

      final storageRef = FirebaseStorage.instance.ref().child(path);
      await storageRef.delete();

      print('Invitation letter deleted successfully: $path');
      return true;
    } catch (e) {
      print('Failed to delete invitation letter: $e');
      return false;
    }
  }
}
