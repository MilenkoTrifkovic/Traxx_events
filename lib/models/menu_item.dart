import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

class MenuItem {
  final String? menuItemId; // Firestore doc id
  final String? menuId; // Links to menus/{menuId}
  final String? organisationId;

  final String name;
  final MenuCategory category;

  final String? description;
  final String? imagePath;
  final String? imageUrl;

  /// NEW: price of the item (optional)
  final double? price;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool isDisabled;

  MenuItem({
    this.menuItemId,
    this.menuId,
    this.organisationId,
    required this.name,
    required this.category,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.isDisabled = false,
  });

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'menuItemId': menuItemId,
      'menuId': menuId,
      'organisationId': organisationId,
      'name': name,
      'category': category.name,
      'description': description,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'price': price,
      'isDisabled': isDisabled,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'menuItemId': menuItemId,
      'menuId': menuId,
      'organisationId': organisationId,
      'name': name,
      'category': category.name,
      'description': description,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'price': price,
      'isDisabled': isDisabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MenuItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return MenuItem(
      menuItemId: id ?? data['menuItemId'] as String?,
      menuId: data['menuId'] as String?,
      organisationId: data['organisationId'] as String?,
      name: data['name'] as String? ?? '',
      category: MenuCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => MenuCategory.other,
      ),
      description: data['description'] as String?,
      imagePath: data['imagePath'] as String?,
      imageUrl: data['imageUrl'] as String?,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isDisabled: data['isDisabled'] as bool? ?? false,
    );
  }

  MenuItem copyWith({
    String? menuItemId,
    String? menuId,
    String? organisationId,
    String? name,
    MenuCategory? category,
    String? description,
    String? imagePath,
    String? imageUrl,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDisabled,
  }) {
    return MenuItem(
      menuItemId: menuItemId ?? this.menuItemId,
      menuId: menuId ?? this.menuId,
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
