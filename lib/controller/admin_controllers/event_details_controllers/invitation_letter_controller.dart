import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:universal_html/html.dart' as html;

class InvitationLetterController extends GetxController {
  final StorageServices _storageServices = Get.find<StorageServices>();
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final SnackbarMessageController _snackbarController = Get.find<SnackbarMessageController>();

  /// Selected file for the invitation letter (local, not yet uploaded)
  Rx<PlatformFile?> invitationFile = Rx<PlatformFile?>(null);

  /// Uploaded invitation letter URL from Firebase Storage
  RxString invitationLetterUrl = ''.obs;

  /// Uploaded invitation letter path in Firebase Storage
  RxString invitationLetterPath = ''.obs;

  /// Loading state for file picker
  RxBool isLoading = false.obs;

  /// Loading state for upload
  RxBool isUploading = false.obs;

  /// Error message
  RxString errorMessage = ''.obs;

  /// Current event
  Rx<Event?> currentEvent = Rx<Event?>(null);

  /// Initialize controller with event data
  void initializeWithEvent(Event event) {
    currentEvent.value = event;
    invitationLetterUrl.value = event.invitationLetterUrl ?? '';
    invitationLetterPath.value = event.invitationLetterPath ?? '';
    print('Letter image URL: ${invitationLetterUrl.value}');
    print('Letter image path: ${invitationLetterPath.value}');
  }

  /// Pick a file (PDF or Image) for the invitation letter
  Future<void> pickInvitationFile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Allow PDF and image files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true, // Load file bytes for preview and upload
      );

      if (result != null && result.files.isNotEmpty) {
        invitationFile.value = result.files.first;
        print('File selected: ${invitationFile.value?.name}');
        print('File bytes available: ${invitationFile.value?.bytes != null}');
      } else {
        print('No file selected');
      }
    } catch (e) {
      errorMessage.value = 'Failed to pick file: $e';
      print('Error picking file: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload invitation letter and save to Firestore
  Future<void> uploadAndSaveInvitationLetter() async {
    try {
      // Validate inputs
      if (invitationFile.value == null) {
        errorMessage.value = 'Please select a file first';
        return;
      }

      if (currentEvent.value == null || currentEvent.value!.eventId == null) {
        errorMessage.value = 'Event not initialized';
        return;
      }

      isUploading.value = true;
      errorMessage.value = '';

      final file = invitationFile.value!;
      final eventId = currentEvent.value!.eventId!;

      print('Uploading invitation letter for event: $eventId');

      // Step 1: Upload to Firebase Storage
      final uploadResult = await _storageServices.uploadInvitationLetter(
        file,
        eventId,
      );

      final path = uploadResult['path']!;
      final downloadUrl = uploadResult['downloadUrl']!;

      print('Upload successful - Path: $path, URL: $downloadUrl');

      // Step 2: Update event in Firestore
      final updatedEvent = currentEvent.value!.copyWith(
        invitationLetterPath: path,
        invitationLetterUrl: downloadUrl,
      );

      await _firestoreServices.updateEvent(updatedEvent);

      print('Event updated in Firestore');

      // Step 3: Update local state
      currentEvent.value = updatedEvent;
      invitationLetterPath.value = path;
      invitationLetterUrl.value = downloadUrl;
      
      // Clear the local file since it's now uploaded
      invitationFile.value = null;

      // Show success message
      _snackbarController.showSuccessMessage('Invitation letter uploaded successfully');
    } catch (e) {
      errorMessage.value = 'Failed to upload: $e';
      print('Error uploading invitation letter: $e');
      _snackbarController.showErrorMessage('Failed to upload invitation letter: $e');
    } finally {
      isUploading.value = false;
    }
  }

  /// Delete the uploaded invitation letter
  Future<void> deleteInvitationLetter() async {
    try {
      if (invitationLetterPath.value.isEmpty) {
        print('No invitation letter to delete');
        return;
      }

      if (currentEvent.value == null || currentEvent.value!.eventId == null) {
        errorMessage.value = 'Event not initialized';
        return;
      }

      isUploading.value = true;
      errorMessage.value = '';

      // Step 1: Delete from Firebase Storage
      await _storageServices.deleteInvitationLetter(invitationLetterPath.value);

      // Step 2: Update event in Firestore
      final updatedEvent = currentEvent.value!.copyWith(
        invitationLetterPath: '',
        invitationLetterUrl: '',
      );

      await _firestoreServices.updateEvent(updatedEvent);

      // Step 3: Update local state
      currentEvent.value = updatedEvent;
      invitationLetterPath.value = '';
      invitationLetterUrl.value = '';

      _snackbarController.showSuccessMessage('Invitation letter deleted successfully');
    } catch (e) {
      errorMessage.value = 'Failed to delete: $e';
      print('Error deleting invitation letter: $e');
      _snackbarController.showErrorMessage('Failed to delete invitation letter: $e');
    } finally {
      isUploading.value = false;
    }
  }

  /// Remove the selected file (local only, doesn't delete from storage)
  void removeFile() {
    invitationFile.value = null;
    errorMessage.value = '';
    print('File removed from selection');
  }

  /// Check if there's an uploaded file
  bool hasUploadedFile() {
    return invitationLetterUrl.value.isNotEmpty;
  }

  /// Check if there's a locally selected file waiting to be uploaded
  bool hasLocalFile() {
    return invitationFile.value != null;
  }

  /// Get file size in readable format
  String getFileSize() {
    if (invitationFile.value == null) return '';
    
    final bytes = invitationFile.value!.size;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get file extension
  String? getFileExtension() {
    return invitationFile.value?.extension;
  }

  /// Check if file is an image
  bool isImage() {
    final extension = getFileExtension()?.toLowerCase();
    return extension == 'jpg' || extension == 'jpeg' || extension == 'png';
  }

  /// Check if file is a PDF
  bool isPdf() {
    return getFileExtension()?.toLowerCase() == 'pdf';
  }

  /// Download the uploaded invitation letter
  Future<void> downloadInvitationLetter() async {
    try {
      if (invitationLetterUrl.value.isEmpty) {
        _snackbarController.showErrorMessage('No file to download');
        return;
      }

      if (invitationLetterPath.value.isEmpty) {
        _snackbarController.showErrorMessage('File path not found');
        return;
      }

      // Get filename from path
      final fileName = invitationLetterPath.value.split('/').last;
      
      // Show downloading message
      _snackbarController.showInfoMessage('Downloading $fileName...');

      // For web platform, use anchor element to trigger download
      final anchor = html.AnchorElement(href: invitationLetterUrl.value)
        ..target = 'blank'
        ..download = fileName;
      
      // Trigger download
      anchor.click();

      // Show success message after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _snackbarController.showSuccessMessage('$fileName downloaded successfully');
      
    } catch (e) {
      print('Error downloading invitation letter: $e');
      _snackbarController.showErrorMessage('Failed to download file: $e');
    }
  }

  @override
  void onClose() {
    invitationFile.value = null;
    currentEvent.value = null;
    super.onClose();
  }
}
