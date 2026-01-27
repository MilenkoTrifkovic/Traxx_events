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
  final String
      category; // Changed from MenuCategory enum to String to support custom categories

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
      category: data['category'] as String? ??
          'Other', // Direct string assignment with fallback
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

/// ✅ Group DTO returned by Cloud Function
class MenuGroupDto {
  final String groupId;
  final String name;
  final int maxPick;
  final String categoryKey;
  final String categoryLabel;
  final List<MenuItemDto> items;

  MenuGroupDto({
    required this.groupId,
    required this.name,
    required this.maxPick,
    required this.categoryKey,
    required this.categoryLabel,
    required this.items,
  });

  factory MenuGroupDto.fromMap(Map<String, dynamic> m) {
    final rawItems = (m['items'] as List? ?? []);
    return MenuGroupDto(
      groupId: (m['groupId'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      maxPick: (m['maxPick'] is num) ? (m['maxPick'] as num).toInt() : 1,
      categoryKey: (m['categoryKey'] ?? '').toString(),
      categoryLabel: (m['categoryLabel'] ?? '').toString(),
      items: rawItems
          .whereType<Map>()
          .map((x) => MenuItemDto.fromMap(Map<String, dynamic>.from(x)))
          .toList(),
    );
  }
}

/// DTO for menu items displayed in the UI.
class MenuItemDto {
  final String id;
  final String name;
  final String description;
  final String categoryLabel;
  final bool? isVeg;
  final String? foodType;
  final double? price;
  final String? imageUrl;

  MenuItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryLabel,
    required this.isVeg,
    required this.foodType,
    required this.price,
    this.imageUrl,
  });

  factory MenuItemDto.fromMap(Map<String, dynamic> m) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final rawFoodType = (m['foodType'] ?? '').toString();
    final parsedIsVeg = _parseBool(m['isVeg']);
    final derivedIsVeg = parsedIsVeg ?? _deriveIsVegFromFoodType(rawFoodType);

    final labelFromCf = (m['categoryLabel'] ?? '').toString().trim();
    final rawCategory = (m['categoryKey'] ?? m['category'] ?? '').toString();

    return MenuItemDto(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Menu item').toString(),
      description: (m['description'] ?? '').toString(),
      categoryLabel:
          labelFromCf.isNotEmpty ? labelFromCf : _prettyCategory(rawCategory),
      isVeg: derivedIsVeg,
      foodType: rawFoodType.trim().isEmpty ? null : rawFoodType.trim(),
      price: asDouble(m['price']),
      imageUrl:
          m['imageUrl'] != null && m['imageUrl'].toString().trim().isNotEmpty
              ? m['imageUrl'].toString()
              : null,
    );
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static bool? _deriveIsVegFromFoodType(String? ft) {
    final s = (ft ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'veg' || s == 'vegetarian') return true;
    if (s == 'non-veg' || s == 'nonveg' || s == 'non vegetarian') return false;
    if (s.contains('non')) return false;
    return null;
  }

  static String _prettyCategory(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 'Other';

    final lower = s.toLowerCase();
    if (lower == 'dessert') return 'Desserts';
    if (lower == 'entree') return 'Entrees';
    if (lower == 'appetizer') return 'Appetizers';
    if (lower == 'drink') return 'Beverages';

    final spaced =
        s.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').trim();
    final title = spaced.split(' ').where((w) => w.isNotEmpty).map((w) {
      final t = w.toLowerCase();
      if (t == 'bbq') return 'BBQ';
      return t[0].toUpperCase() + t.substring(1);
    }).join(' ');

    if (s == 'lateNightSnacks') return 'Late-Night Snacks';
    if (s == 'kidsMenu') return 'Kids Menu';
    if (s == 'culturalRegional') return 'Cultural / Regional';
    if (s == 'dietSpecific') return 'Diet-Specific';

    return title;
  }
}

enum DietPreference { veg, nonVeg, both }

extension DietPreferenceX on DietPreference {
  String get dbValue {
    switch (this) {
      case DietPreference.veg:
        return 'veg';
      case DietPreference.nonVeg:
        return 'non_veg';
      case DietPreference.both:
        return 'both';
    }
  }

  String get label {
    switch (this) {
      case DietPreference.veg:
        return 'Veg';
      case DietPreference.nonVeg:
        return 'Non-Veg';
      case DietPreference.both:
        return 'Both';
    }
  }

  static DietPreference? fromDb(String? v) {
    final s = (v ?? '').trim();
    if (s == 'veg') return DietPreference.veg;
    if (s == 'non_veg' || s == 'non-veg') return DietPreference.nonVeg;
    if (s == 'both') return DietPreference.both;
    return null;
  }
}

bool matchesDiet(MenuItemDto it, DietPreference pref) {
  final v = it.isVeg; // true=veg, false=non-veg, null=unknown
  if (pref == DietPreference.both) return true;

  // ✅ keep “unknown” visible (so items without tags don't disappear)
  if (v == null) return true;

  if (pref == DietPreference.veg) return v == true;
  return v == false; // nonVeg
}
