import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/global_controllers/menu_selection_controller.dart';
import 'menu_constants.dart';

/// A search and filter card widget for menu items.
class MenuSearchFilters extends StatelessWidget {
  final TextEditingController searchController;
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    controller
                        .clearFilters(); // clears searchQuery + old vegFilter
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
