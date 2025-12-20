import 'package:cloud_firestore/cloud_firestore.dart';

enum FoodType { veg, nonVeg }

extension FoodTypeExt on FoodType {
  String label() {
    switch (this) {
      case FoodType.veg:
        return 'Veg';
      case FoodType.nonVeg:
        return 'Non-Veg';
      default:
        return '';
    }
  }
}

class MenuItem {
  final String? menuItemId; // Firestore doc id
  final String? menuId; // Links to menus/{menuId}
  final String? organisationId;

  final String name;
  final String category; // Changed from MenuCategory enum to String to support custom categories

  final String? description;
  final String? imagePath;
  final String? imageUrl;

  /// NEW: price of the item (optional)
  final double? price;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool isDisabled;
  final FoodType? foodType;

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
    this.foodType,
  });

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'menuItemId': menuItemId,
      'menuId': menuId,
      'organisationId': organisationId,
      'name': name,
      'category': category, // Now already a string
      'description': description,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'price': price,
      'isDisabled': isDisabled,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'foodType': foodType == null
          ? null
          : (foodType == FoodType.veg ? 'veg' : 'non_veg'),
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'menuItemId': menuItemId,
      'menuId': menuId,
      'organisationId': organisationId,
      'name': name,
      'category': category, // Now already a string
      'description': description,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'price': price,
      'isDisabled': isDisabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'foodType': foodType == null
          ? null
          : (foodType == FoodType.veg ? 'veg' : 'non_veg'),
    };
  }

  factory MenuItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    final ft = data['foodType'] as String?;
    FoodType? parsedFoodType;
    if (ft == 'veg') {
      parsedFoodType = FoodType.veg;
    } else if (ft == 'non_veg') {
      parsedFoodType = FoodType.nonVeg;
    }
    return MenuItem(
      menuItemId: id ?? data['menuItemId'] as String?,
      menuId: data['menuId'] as String?,
      organisationId: data['organisationId'] as String?,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Other', // Direct string assignment with fallback
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
      foodType: parsedFoodType,
    );
  }

  MenuItem copyWith({
    String? menuItemId,
    String? menuId,
    String? organisationId,
    String? name,
    String? category, // Changed from MenuCategory to String
    String? description,
    String? imagePath,
    String? imageUrl,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDisabled,
    FoodType? foodType,
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
      foodType: foodType ?? this.foodType,
    );
  }
}
