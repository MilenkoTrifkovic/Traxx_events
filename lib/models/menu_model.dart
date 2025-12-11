import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  final String id;
  final String organisationId;
  final String name; // canonical stored field
  final String? description;
  final String? coverImagePath;
  final String? imageUrl;
  final bool isDisabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuModel({
    required this.id,
    required this.organisationId,
    required this.name,
    this.description,
    this.coverImagePath,
    this.imageUrl,
    this.isDisabled = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Backwards/forwards-compatible accessor used in UI code
  String get title => name;

  /// Create a copy with optional overrides
  MenuModel copyWith({
    String? id,
    String? organisationId,
    String? name,
    String? description,
    String? coverImagePath,
    String? imageUrl,
    bool? isDisabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuModel(
      id: id ?? this.id,
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Robust factory: accepts map data from Firestore and document id
  factory MenuModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Some older documents may use 'title' instead of 'name'
    final nameField = data['name'] ?? data['title'] ?? '';

    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      throw ArgumentError('Unsupported timestamp value: $value');
    }

    return MenuModel(
      id: id,
      organisationId: data['organisationId'] ?? '',
      name: nameField,
      description: (data['description'] as String?)?.trim(),
      coverImagePath: data['coverImagePath'] as String?,
      imageUrl: data['imageUrl'] as String?,
      isDisabled: data['isDisabled'] == true,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  /// Prepare a map suitable for saving to Firestore.
  /// Includes both 'name' and 'title' keys for compatibility with older code.
  Map<String, dynamic> toFirestore() {
    return {
      'menuId': id,
      'organisationId': organisationId,
      'name': name,
      'title': name, // duplicate for compatibility
      'description': description,
      'coverImagePath': coverImagePath,
      'imageUrl': imageUrl,
      'isDisabled': isDisabled,
      // Store DateTime as Timestamp if available
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
