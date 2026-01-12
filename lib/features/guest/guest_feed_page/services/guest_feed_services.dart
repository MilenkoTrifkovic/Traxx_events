import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/message.dart';
import 'package:uuid/uuid.dart';

/// Service layer responsible for chat/feed communication with Firestore.
/// 
/// Architecture principles:
/// - Receives fully constructed Message models
/// - No business logic (belongs to controller)
/// - Only handles persistence and real-time data transport
/// - No UI logic or local state
/// - Designed for future scalability and migration
class GuestFeedServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Creates a new message in Firestore.
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [message]: Fully constructed Message model
  /// 
  /// Returns:
  /// - The created Message with generated messageId
  /// 
  /// Responsibilities:
  /// - Generates UUID v4 for messageId and document ID
  /// - Persists under: events/{eventId}/messages/{messageId}
  /// - Relies on Firestore server timestamps
  /// 
  /// Throws:
  /// - [FirebaseException] if the operation fails
  Future<Message> createMessage({
    required String eventId,
    required Message message,
  }) async {
    try {
      // Generate UUID v4
      final messageId = _uuid.v4();

      // Create message with generated ID
      final messageWithId = message.copyWith(messageId: messageId);

      // Persist to Firestore using toFirestore() for server timestamps
      await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .set(messageWithId.toFirestore());

      return messageWithId;
    } on FirebaseException catch (e) {
      print('Firestore error creating message: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error creating message: $e');
      rethrow;
    }
  }

  /// Provides a real-time stream of messages for an event.
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [limit]: Maximum number of messages to retrieve (default: 20)
  /// 
  /// Returns:
  /// - Stream<List<Message>> with real-time updates
  /// 
  /// Behavior:
  /// - Uses Firestore real-time listener
  /// - Orders by createdAt descending (newest first)
  /// - Maps documents using Message.fromFirestore()
  /// - Automatically updates when new messages arrive
  Stream<List<Message>> getMessagesStream({
    required String eventId,
    int limit = 20,
  }) {
    try {
      return _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .where('isDisabled', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error setting up messages stream: $e');
      rethrow;
    }
  }

  /// Loads older messages using cursor-based pagination.
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [lastDocument]: The last document from previous query (cursor)
  /// - [limit]: Number of messages to load (default: 20)
  /// 
  /// Returns:
  /// - Future<List<Message>> containing older messages
  /// 
  /// Rules:
  /// - Uses cursor-based pagination with startAfter
  /// - No index-based ranges
  /// - No real-time listener (one-time fetch)
  /// - Orders by createdAt descending
  /// 
  /// Throws:
  /// - [FirebaseException] if the operation fails
  Future<List<Message>> loadOlderMessages({
    required String eventId,
    required DocumentSnapshot lastDocument,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .where('isDisabled', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      print('Firestore error loading older messages: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error loading older messages: $e');
      rethrow;
    }
  }

  /// Updates an existing message in Firestore.
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [message]: Message model with updated fields
  /// 
  /// Responsibilities:
  /// - Updates text and attachments
  /// - Updates modifiedAt using server timestamp
  /// 
  /// Throws:
  /// - [FirebaseException] if the operation fails
  /// - [Exception] if messageId is null
  Future<void> updateMessage({
    required String eventId,
    required Message message,
  }) async {
    if (message.messageId == null) {
      throw Exception('Cannot update message without messageId');
    }

    try {
      final updateData = {
        'text': message.text,
        'attachments': message.attachments.map((e) => e.toJson()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      };

      await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(message.messageId)
          .update(updateData);
    } on FirebaseException catch (e) {
      print('Firestore error updating message: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating message: $e');
      rethrow;
    }
  }

  /// Soft deletes a message by setting isDisabled = true.
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [messageId]: The message identifier
  /// 
  /// Responsibilities:
  /// - Sets isDisabled = true
  /// - Updates modifiedAt using server timestamp
  /// - Does not physically delete the document
  /// 
  /// Throws:
  /// - [FirebaseException] if the operation fails
  Future<void> softDeleteMessage({
    required String eventId,
    required String messageId,
  }) async {
    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDisabled': true,
        'modifiedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Firestore error soft deleting message: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error soft deleting message: $e');
      rethrow;
    }
  }

  /// Gets a single message by ID (one-time fetch).
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [messageId]: The message identifier
  /// 
  /// Returns:
  /// - Message if found
  /// 
  /// Throws:
  /// - [Exception] if message not found
  /// - [FirebaseException] if the operation fails
  Future<Message> getMessageById({
    required String eventId,
    required String messageId,
  }) async {
    try {
      final docSnapshot = await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Message not found: $messageId');
      }

      return Message.fromFirestore(docSnapshot);
    } on FirebaseException catch (e) {
      print('Firestore error getting message: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error getting message: $e');
      rethrow;
    }
  }

  /// Gets the Firestore document for a message (used for pagination cursor).
  /// 
  /// Parameters:
  /// - [eventId]: The event identifier
  /// - [messageId]: The message identifier
  /// 
  /// Returns:
  /// - DocumentSnapshot for use with loadOlderMessages
  /// 
  /// Throws:
  /// - [Exception] if message not found
  /// - [FirebaseException] if the operation fails
  Future<DocumentSnapshot> getMessageDocument({
    required String eventId,
    required String messageId,
  }) async {
    try {
      final docSnapshot = await _db
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Message document not found: $messageId');
      }

      return docSnapshot;
    } on FirebaseException catch (e) {
      print('Firestore error getting message document: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error getting message document: $e');
      rethrow;
    }
  }
}