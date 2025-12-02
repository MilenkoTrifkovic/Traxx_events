import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

class MenuItem {
  final String? menuItemId;
  final String? organisationId;
  final String name;
  final MenuCategory category;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool isDisabled;

  MenuItem({
    this.menuItemId,
    this.organisationId,
    required this.name,
    required this.category,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
  });

  // Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'category': category.name,
      'description': description,
      'imagePath': imagePath,
      'organisationId': organisationId,
      'isDisabled': isDisabled,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  // Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'category': category.name,
      'description': description,
      'imagePath': imagePath,
      'organisationId': organisationId,
      'isDisabled': isDisabled,
      // keep old createdAt, only update modifiedAt
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MenuItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return MenuItem(
      organisationId: (data['organisationId'] ?? data['venuID']) as String?,
      menuItemId: id ?? data['menuItemId'] as String?,
      name: data['name'] as String,
      category: MenuCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => MenuCategory.other,
      ),
      description: data['description'] as String?,
      imagePath: data['imagePath'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      modifiedAt: (data['modifiedAt'] is Timestamp)
          ? (data['modifiedAt'] as Timestamp).toDate()
          : null,
      isDisabled: data['isDisabled'] as bool? ?? false,
    );
  }

  MenuItem copyWith({
    String? menuItemId,
    String? organisationId,
    String? name,
    MenuCategory? category,
    String? description,
    String? imagePath,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
  }) {
    return MenuItem(
      menuItemId: menuItemId ?? this.menuItemId,
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
