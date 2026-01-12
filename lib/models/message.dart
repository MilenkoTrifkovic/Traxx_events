import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/attachment_type.dart';

/// Represents an attachment in a message (image, pdf, etc.)
class MessageAttachment {
  final AttachmentType type;
  final String url;
  final String name;

  MessageAttachment({
    required this.type,
    required this.url,
    required this.name,
  });

  /// Creates a MessageAttachment from a JSON map
  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      type: AttachmentTypeExtension.fromString(json['type'] as String),
      url: json['url'] as String,
      name: json['name'] as String,
    );
  }

  /// Converts the MessageAttachment to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'url': url,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'MessageAttachment(type: ${type.name}, url: $url, name: $name)';
  }
}

/// Represents a message in the chat/messaging system
class Message {
  final String? messageId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String text;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final List<MessageAttachment> attachments;
  final bool isDisabled;

  Message({
    this.messageId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.text,
    this.createdAt,
    this.modifiedAt,
    this.attachments = const [],
    this.isDisabled = false,
  });

  /// Creates a Message instance from a Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse timestamps safely
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    // Parse attachments list
    final attachmentsList = (data['attachments'] as List<dynamic>?)
            ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return Message(
      messageId: data['messageId'] as String?,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userPhoto: data['userPhoto'] as String?,
      text: data['text'] as String,
      createdAt: parseTimestamp(data['createdAt']),
      modifiedAt: parseTimestamp(data['modifiedAt']),
      attachments: attachmentsList,
      isDisabled: data['isDisabled'] as bool? ?? false,
    );
  }

  /// Converts the Message instance to a JSON map for Firestore storage
  /// Note: createdAt and modifiedAt will be set by Firestore server timestamp
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'text': text,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'modifiedAt': modifiedAt != null ? Timestamp.fromDate(modifiedAt!) : FieldValue.serverTimestamp(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'isDisabled': isDisabled,
    };
  }

  /// Converts the Message instance to a Firestore document map
  /// Use this when saving new messages - it uses server timestamps
  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'isDisabled': isDisabled,
    };
  }

  /// Creates a copy of this Message with the specified fields replaced
  Message copyWith({
    String? messageId,
    String? userId,
    String? userName,
    String? userPhoto,
    String? text,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<MessageAttachment>? attachments,
    bool? isDisabled,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      attachments: attachments ?? this.attachments,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  @override
  String toString() {
    return '''
Message {
  messageId: $messageId
  userId: $userId
  userName: $userName
  userPhoto: $userPhoto
  text: $text
  createdAt: $createdAt
  modifiedAt: $modifiedAt
  attachments: $attachments
  isDisabled: $isDisabled
}''';
  }
}
