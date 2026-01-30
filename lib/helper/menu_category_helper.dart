import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

/// Helper class to manage menu categories combining enum values with
/// custom categories from the organisation.
class MenuCategoryHelper {
  static List<String> getAllCategories({String? include}) {
    // key = normalized lower-case, value = display text
    final Map<String, String> map = {};

    void add(String raw) {
      final display = formatCategoryName(raw);
      final key = _normKey(display);
      if (key.isEmpty) return;
      map.putIfAbsent(key, () => display);
    }

    // 1) enum
    for (final c in MenuCategory.values) {
      add(c.name);
    }

    // 2) org custom
    try {
      final orgController = Get.find<OrganisationController>();
      final custom =
          orgController.organisation.value?.customMenuCategories ?? [];
      for (final x in custom) {
        add(x);
      }
    } catch (_) {}

    // 3) ensure current value is available (fixes edit crash)
    if (include != null && include.trim().isNotEmpty) {
      add(include);
    }

    final out = map.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  static List<DropdownMenuItem<String>> getCategoryDropdownItems(
      {String? include}) {
    final cats = getAllCategories(include: include);
    return cats
        .map((c) => DropdownMenuItem<String>(
              value: c,
              child: Text(c),
            ))
        .toList();
  }

  static List<DropdownMenuItem<String?>> getCategoryFilterItems(
      {String? include}) {
    final cats = getAllCategories(include: include);
    return [
      const DropdownMenuItem<String?>(
          value: null, child: Text('All categories')),
      ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
    ];
  }

  static MenuCategory? getEnumFromString(String name) {
    final normalized = _normKey(formatCategoryName(name));
    for (final c in MenuCategory.values) {
      final formatted = formatCategoryName(c.name);
      if (_normKey(formatted) == normalized) return c;
    }
    return null;
  }

  static bool isEnumCategory(String name) => getEnumFromString(name) != null;

  static String formatCategoryName(String name) {
    if (name.trim().isEmpty) return 'Other';

    final raw = name.trim();

    // Add spaces before capitals (kidsMenu -> kids Menu)
    final spaced =
        raw.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').trim();

    // Collapse multiple spaces (important)
    final clean = spaced.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Title case words
    return clean
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static String _normKey(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// Metadata for a menu category
class CategoryMetadata {
  final IconData icon;
  final bool isVeg;

  CategoryMetadata({required this.icon, required this.isVeg});
}
