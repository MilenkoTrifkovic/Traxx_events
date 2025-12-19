import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

/// Helper class to manage menu categories combining enum values with
/// custom categories from the organisation.
class MenuCategoryHelper {
  /// Gets all available menu categories by combining:
  /// 1. Predefined enum values
  /// 2. Custom categories from the organisation (if any)
  ///
  /// Returns a sorted list with no duplicates.
  static List<String> getAllCategories() {
    final Set<String> categories = {};

    // Add all enum categories (formatted)
    for (final category in MenuCategory.values) {
      categories.add(formatCategoryName(category.name));
    }

    // Add custom categories from organisation if available
    try {
      final orgController = Get.find<OrganisationController>();
      final customCategories =
          orgController.organisation.value?.customMenuCategories;

      if (customCategories != null && customCategories.isNotEmpty) {
        for (final custom in customCategories) {
          final trimmed = custom.trim();
          if (trimmed.isNotEmpty) {
            // Format custom categories the same way as enum categories
            categories.add(formatCategoryName(trimmed));
          }
        }
      }
    } catch (e) {
      // OrganisationController not found or not initialized
      // Continue with just enum values
    }

    // Convert to list and sort alphabetically (case-insensitive)
    final sortedList = categories.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }

  /// Gets dropdown menu items for all categories
  static List<DropdownMenuItem<String>> getCategoryDropdownItems() {
    return getAllCategories()
        .map((category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ))
        .toList();
  }

  /// Gets dropdown menu items for category filter (includes "All categories" option)
  static List<DropdownMenuItem<String?>> getCategoryFilterItems() {
    return [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('All categories'),
      ),
      ...getAllCategories()
          .map((category) => DropdownMenuItem<String?>(
                value: category,
                child: Text(category),
              ))
          .toList(),
    ];
  }

  /// Gets a MenuCategory enum value from a string name (case-insensitive).
  /// Returns null if the name doesn't match any enum value.
  static MenuCategory? getEnumFromString(String name) {
    final normalized = name.toLowerCase().trim();
    
    for (final category in MenuCategory.values) {
      final formattedName = formatCategoryName(category.name);
      if (formattedName.toLowerCase() == normalized) {
        return category;
      }
    }
    
    return null;
  }

  /// Checks if a category name corresponds to a predefined enum value.
  static bool isEnumCategory(String name) {
    return getEnumFromString(name) != null;
  }

  /// Formats a category name for display (capitalizes first letter).
  /// Handles camelCase by adding spaces before capitals.
  static String formatCategoryName(String name) {
    if (name.isEmpty) return 'Other';
    
    // Add spaces before capital letters (for camelCase like "kidsMenu" -> "Kids Menu")
    final withSpaces = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
    
    // Capitalize first letter of each word
    return withSpaces
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Gets the icon and isVeg property for a category.
  /// Returns null if the category is custom (not in enum).
  static CategoryMetadata? getCategoryMetadata(String name) {
    final enumValue = getEnumFromString(name);
    if (enumValue == null) return null;
    
    return CategoryMetadata(icon: enumValue.icon, isVeg: enumValue.isVeg);
  }
}

/// Metadata for a menu category
class CategoryMetadata {
  final IconData icon;
  final bool isVeg;

  CategoryMetadata({required this.icon, required this.isVeg});
}
