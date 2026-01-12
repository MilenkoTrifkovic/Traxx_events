import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/menu_selection_controller.dart';
import 'menu_constants.dart';
import 'menu_filter_chip.dart';

/// A search and filter card widget for menu items.
class MenuSearchFilters extends StatelessWidget {
  /// The search text controller.
  final TextEditingController searchController;

  /// The menu selection controller.
  final MenuSelectionController controller;

  const MenuSearchFilters({
    super.key,
    required this.searchController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search dish name, e.g. "rice"',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Obx(() => Row(
              children: [
                MenuFilterChip(
                  label: 'All (${controller.items.length})',
                  icon: Icons.restaurant_menu_rounded,
                  selected: controller.vegFilter.value == null,
                  onTap: () => controller.setVegFilter(null),
                ),
                const SizedBox(width: 8),
                MenuFilterChip(
                  label: 'Veg (${controller.vegCount})',
                  icon: Icons.eco_rounded,
                  selected: controller.vegFilter.value == true,
                  onTap: () => controller.setVegFilter(true),
                ),
                const SizedBox(width: 8),
                MenuFilterChip(
                  label: 'Non-Veg (${controller.nonVegCount})',
                  icon: Icons.set_meal_rounded,
                  selected: controller.vegFilter.value == false,
                  onTap: () => controller.setVegFilter(false),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    controller.clearFilters();
                  },
                  child: const Text('Clear'),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
