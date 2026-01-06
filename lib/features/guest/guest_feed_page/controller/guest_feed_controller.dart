import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/services/guest_feed_services.dart';
import 'package:traxx_wepapp/models/message.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/attachment_type.dart';

/// Controller for Guest Feed Page
///
/// Manages the state and business logic for the event feed/chat functionality.
/// Responsibilities:
/// - Manages text input and file upload state
/// - Coordinates with GuestFeedServices for data operations
/// - Handles message sending logic
/// - Manages message list state
class GuestFeedController extends GetxController {
  final GuestFeedServices _feedServices = GuestFeedServices();
  final StorageServices _storageServices = StorageServices();

  // Event ID
  final String eventId;

  // Input controllers
  final TextEditingController messageTextController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();

  // File upload state
  final Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);
  final RxString selectedFileName = ''.obs;
  final RxString selectedFileType = ''.obs;

  // Message list state
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Scroll controller for pagination
  final ScrollController scrollController = ScrollController();

  GuestFeedController({required this.eventId});

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    loadMessages();
  }

  @override
  void onClose() {
    messageTextController.dispose();
    messageFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Sets up scroll listener for pagination
  void _setupScrollListener() {
    scrollController.addListener(() {
      // Load more messages when scrolled to top (older messages)
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        loadOlderMessages();
      }
    });
  }

  /// Loads initial messages from Firestore
  Future<void> loadMessages() async {
    try {
      isLoading.value = true;

      // Subscribe to real-time stream
      _feedServices.getMessagesStream(eventId: eventId).listen(
        (messageList) {
          messages.value = messageList;
          isLoading.value = false;
        },
        onError: (error) {
          print('Error loading messages: $error');
          isLoading.value = false;
          // TODO: Show error to user
        },
      );
    } catch (e) {
      print('Error setting up message stream: $e');
      isLoading.value = false;
      // TODO: Show error to user
    }
  }

  /// Loads older messages using pagination
  Future<void> loadOlderMessages() async {
    if (messages.isEmpty || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;

      final lastMessage = messages.last;
      if (lastMessage.messageId == null) {
        isLoadingMore.value = false;
        return;
      }

      // Get the document snapshot for cursor
      final lastDoc = await _feedServices.getMessageDocument(
        eventId: eventId,
        messageId: lastMessage.messageId!,
      );

      // Load older messages
      final olderMessages = await _feedServices.loadOlderMessages(
        eventId: eventId,
        lastDocument: lastDoc,
      );

      // Add to existing list
      messages.addAll(olderMessages);
      isLoadingMore.value = false;
    } catch (e) {
      print('Error loading older messages: $e');
      isLoadingMore.value = false;
      // TODO: Show error to user
    }
  }

  /// Sends a message with text and optional file attachment
  Future<void> sendMessage() async {
    final text = messageTextController.text.trim();

    // Validate input
    if (text.isEmpty && selectedFile.value == null) {
      print('Cannot send empty message');
      return;
    }

    try {
      isSending.value = true;

      // Get user data from GuestSessionController
      final sessionController = Get.find<GuestSessionController>();
      final currentGuest = sessionController.guest.value;

      if (currentGuest == null) {
        print('❌ Cannot send message: Guest not found in session');
        isSending.value = false;
        return;
      }

      final userId = currentGuest.guestId ?? 'unknown';
      final userName = currentGuest.name;
      final String? userPhoto = null; // GuestModel doesn't have profile photo

      // Create message attachments if file is selected
      final attachments = <MessageAttachment>[];
      if (selectedFile.value != null) {
        print('📤 Uploading file to Firebase Storage...');
        
        final file = selectedFile.value!;
        
        // Create a temporary message ID for storage organization
        final tempMessageId = DateTime.now().millisecondsSinceEpoch.toString();
        
        try {
          // Upload file to Firebase Storage
          final uploadResult = await _storageServices.uploadMessageAttachment(
            file,
            eventId,
            tempMessageId,
          );
          
          print('✅ File uploaded successfully');
          print('Storage path: ${uploadResult['path']}');
          print('Download URL: ${uploadResult['downloadUrl']}');
          
          // Determine attachment type
          final attachmentType = selectedFileType.value == 'pdf' 
              ? AttachmentType.pdf 
              : AttachmentType.image;
          
          // Create attachment with Firebase Storage URL
          final attachment = MessageAttachment(
            url: uploadResult['downloadUrl']!, // Use Firebase Storage download URL
            name: file.name,
            type: attachmentType,
          );
          attachments.add(attachment);
        } catch (uploadError) {
          print('❌ Error uploading file: $uploadError');
          // TODO: Show error to user
          isSending.value = false;
          return; // Don't send message if file upload fails
        }
      }

      // Create message model
      final message = Message(
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        text: text,
        attachments: attachments,
      );

      // Send message via service
      await _feedServices.createMessage(
        eventId: eventId,
        message: message,
      );

      print('✅ Message sent successfully');

      // Clear inputs after successful send
      messageTextController.clear();
      removePhoto();
      messageFocusNode.unfocus();
    } catch (e) {
      print('❌ Error sending message: $e');
      // TODO: Show error to user
    } finally {
      isSending.value = false;
    }
  }

  /// Selects a file (image or PDF) for upload
  Future<void> selectPhoto() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        selectedFile.value = file;
        selectedFileName.value = file.name;
        
        // Determine file type
        final extension = file.extension?.toLowerCase() ?? '';
        if (extension == 'pdf') {
          selectedFileType.value = 'pdf';
        } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
          selectedFileType.value = 'image';
        }
        
        print('File selected: ${file.name} (${file.size} bytes)');
      }
    } catch (e) {
      print('Error selecting file: $e');
      // TODO: Show error to user
    }
  }

  /// Removes the selected file
  void removePhoto() {
    selectedFile.value = null;
    selectedFileName.value = '';
    selectedFileType.value = '';
  }

  /// Updates an existing message
  // Future<void> updateMessage(Message message) async {
  //   try {
  //     await _feedServices.updateMessage(
  //       eventId: eventId,
  //       message: message,
  //     );
  //   } catch (e) {
  //     print('Error updating message: $e');
  //     // TODO: Show error to user
  //   }
  // }

  /// Soft deletes a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _feedServices.softDeleteMessage(
        eventId: eventId,
        messageId: messageId,
      );
    } catch (e) {
      print('Error deleting message: $e');
      // TODO: Show error to user
    }
  }

  /// Checks if a message is from the current user
  /// Returns true if the message userId matches the current guest's guestId
  bool isMyMessage(String messageUserId) {
    try {
      final sessionController = Get.find<GuestSessionController>();
      final currentGuestId = sessionController.guest.value?.guestId;
      
      if (currentGuestId == null) return false;
      
      return messageUserId == currentGuestId;
    } catch (e) {
      print('Error checking message ownership: $e');
      return false;
    }
  }
}
