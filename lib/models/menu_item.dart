import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  /// Category is stored as String to support custom categories
  final String category;

  final String? description;
  final String? imagePath;
  final String? imageUrl;

  /// Price (optional)
  final double? price;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool isDisabled;
  final FoodType? foodType;

  /// ✅ NEW: Allergens (optional) - stored as keys (see allowedAllergens)
  final List<String>? allergens;

  /// ✅ Canonical 9 allergens (keys used in Firestore)
  static const List<String> allowedAllergens = [
    'dairy',
    'eggs',
    'fish',
    'shellfish',
    'soy',
    'sesame',
    'wheat',
    'peanuts',
    'tree_nuts',
  ];

  const MenuItem({
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
    this.allergens,
  });

  // ----------------------------
  // Firestore helpers
  // ----------------------------

  Map<String, dynamic> toFirestoreCreate() {
    final data = <String, dynamic>{
      'menuItemId': menuItemId,
      'menuId': menuId,
      'organisationId': organisationId,
      'name': name,
      'category': category,
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

    // ✅ Only store allergens if non-empty
    final cleaned = _cleanAllergens(allergens);
    if (cleaned != null && cleaned.isNotEmpty) {
      data['allergens'] = cleaned;
    }

    return data;
  }

  Map<String, dynamic> toFirestoreUpdate() {
    final data = <String, dynamic>{
      'menuItemId': menuItemId,
      'menuId': menuId,
      'organisationId': organisationId,
      'name': name,
      'category': category,
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

    // ✅ Update behavior:
    // - if allergens is null/empty => delete field
    // - else => set cleaned list
    final cleaned = _cleanAllergens(allergens);
    if (cleaned == null || cleaned.isEmpty) {
      data['allergens'] = FieldValue.delete();
    } else {
      data['allergens'] = cleaned;
    }

    return data;
  }

  factory MenuItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    final ft = data['foodType'] as String?;
    FoodType? parsedFoodType;
    if (ft == 'veg') {
      parsedFoodType = FoodType.veg;
    } else if (ft == 'non_veg') {
      parsedFoodType = FoodType.nonVeg;
    }

    // ✅ Parse allergens safely
    final rawAllergens = data['allergens'];
    List<String>? parsedAllergens;
    if (rawAllergens is List) {
      parsedAllergens = rawAllergens
          .map((e) => e.toString().trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toSet()
          .toList();
      // keep only allowed keys (optional but safer)
      parsedAllergens =
          parsedAllergens.where((k) => allowedAllergens.contains(k)).toList();
      parsedAllergens.sort();
      if (parsedAllergens.isEmpty) parsedAllergens = null;
    }

    return MenuItem(
      menuItemId: id ?? data['menuItemId'] as String?,
      menuId: data['menuId'] as String?,
      organisationId: data['organisationId'] as String?,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
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
      allergens: parsedAllergens,
    );
  }

  // ----------------------------
  // copyWith (supports setting null)
  // ----------------------------

  static const Object _sentinel = Object();

  MenuItem copyWith({
    Object? menuItemId = _sentinel,
    Object? menuId = _sentinel,
    Object? organisationId = _sentinel,
    String? name,
    String? category,
    Object? description = _sentinel,
    Object? imagePath = _sentinel,
    Object? imageUrl = _sentinel,
    Object? price = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    bool? isDisabled,
    Object? foodType = _sentinel,
    Object? allergens = _sentinel,
  }) {
    return MenuItem(
      menuItemId:
          menuItemId == _sentinel ? this.menuItemId : menuItemId as String?,
      menuId: menuId == _sentinel ? this.menuId : menuId as String?,
      organisationId: organisationId == _sentinel
          ? this.organisationId
          : organisationId as String?,
      name: name ?? this.name,
      category: category ?? this.category,
      description:
          description == _sentinel ? this.description : description as String?,
      imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      price: price == _sentinel ? this.price : price as double?,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
      isDisabled: isDisabled ?? this.isDisabled,
      foodType: foodType == _sentinel ? this.foodType : foodType as FoodType?,
      allergens:
          allergens == _sentinel ? this.allergens : allergens as List<String>?,
    );
  }

  // ----------------------------
  // Internal sanitizer
  // ----------------------------

  static List<String>? _cleanAllergens(List<String>? input) {
    if (input == null) return null;
    final cleaned = input
        .map((e) => e.trim().toLowerCase())
        .where((k) => k.isNotEmpty && allowedAllergens.contains(k))
        .toSet()
        .toList()
      ..sort();
    return cleaned.isEmpty ? null : cleaned;
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

  final List<String> allergens; // ✅ NEW (always non-null)

  MenuItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryLabel,
    required this.isVeg,
    required this.foodType,
    required this.price,
    this.imageUrl,
    this.allergens = const [], // ✅ NEW
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

    // ✅ allergens parse
    final rawAllergens = m['allergens'];
    final allergens = <String>[];
    if (rawAllergens is List) {
      for (final a in rawAllergens) {
        final s = a.toString().trim().toLowerCase();
        if (s.isNotEmpty) allergens.add(s);
      }
    }

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
      allergens: allergens,
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

class FoodMeta {
  final String label;
  final IconData icon;
  final Color color;

  const FoodMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}
