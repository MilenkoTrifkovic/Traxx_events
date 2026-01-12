/// Enum representing the types of attachments that can be added to a message
enum AttachmentType {
  /// Image attachment (jpg, png, gif, etc.)
  image,

  /// PDF document
  pdf,

  /// Video file
  video,

  /// Audio file
  audio,

  /// Generic document (docx, xlsx, txt, etc.)
  document,

  /// Mixed/multiple types of attachments
  mixed,

  /// Other/unknown file type
  other,
}

/// Extension to provide utility methods for AttachmentType
extension AttachmentTypeExtension on AttachmentType {
  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.pdf:
        return 'PDF';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.audio:
        return 'Audio';
      case AttachmentType.document:
        return 'Document';
      case AttachmentType.mixed:
        return 'Mixed';
      case AttachmentType.other:
        return 'File';
    }
  }

  /// Get the icon name or identifier for this attachment type
  String get icon {
    switch (this) {
      case AttachmentType.image:
        return 'image';
      case AttachmentType.pdf:
        return 'picture_as_pdf';
      case AttachmentType.video:
        return 'video_file';
      case AttachmentType.audio:
        return 'audio_file';
      case AttachmentType.document:
        return 'description';
      case AttachmentType.mixed:
        return 'attachment';
      case AttachmentType.other:
        return 'attach_file';
    }
  }

  /// Convert enum to string value for Firestore storage
  String get name {
    return toString().split('.').last;
  }

  /// Create AttachmentType from string value (from Firestore)
  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AttachmentType.other,
    );
  }

  /// Determine attachment type from file extension
  static AttachmentType fromFileExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    
    // Image types
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(extension)) {
      return AttachmentType.image;
    }
    
    // PDF
    if (extension == 'pdf') {
      return AttachmentType.pdf;
    }
    
    // Video types
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(extension)) {
      return AttachmentType.video;
    }
    
    // Audio types
    if (['mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac'].contains(extension)) {
      return AttachmentType.audio;
    }
    
    // Document types
    if (['doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'].contains(extension)) {
      return AttachmentType.document;
    }
    
    return AttachmentType.other;
  }
}
