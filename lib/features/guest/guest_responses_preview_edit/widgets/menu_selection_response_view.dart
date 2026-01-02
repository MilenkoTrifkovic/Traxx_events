import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/menu_selection_response_model.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget to display menu selection response details in read-only mode
class MenuSelectionResponseView extends StatelessWidget {
  final MenuSelectionResponseModel response;

  const MenuSelectionResponseView({
    super.key,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    if (response.selectedMenuItemIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No menu items selected yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<MenuItem>>(
      future: _fetchMenuItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading menu items',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        final menuItems = snapshot.data ?? [];
        if (menuItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No menu items found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: menuItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // Food type indicator
                    if (item.foodType != null)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.foodType == FoodType.veg
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (item.category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Food type label
                    if (item.foodType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.foodType == FoodType.veg
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.foodType!.label(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.foodType == FoodType.veg
                                ? Colors.green[800]
                                : Colors.red[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<MenuItem>> _fetchMenuItems() async {
    try {
      if (response.selectedMenuItemIds.isEmpty) {
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('menu_items')
          .where(FieldPath.documentId, whereIn: response.selectedMenuItemIds)
          .get();

      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching menu items: $e');
      return [];
    }
  }
}
