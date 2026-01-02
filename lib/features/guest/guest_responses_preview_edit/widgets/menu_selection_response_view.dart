import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/menu_selection_response_model.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: AppText.styledBodyMedium(
          context,
          'No menu items selected yet',
          color: AppColors.textMuted,
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
            child: AppText.styledBodyMedium(
              context,
              'Error loading menu items',
              color: AppColors.inputError,
            ),
          );
        }

        final menuItems = snapshot.data ?? [];
        if (menuItems.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppText.styledBodyMedium(
              context,
              'No menu items found',
              color: AppColors.textMuted,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: menuItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food type indicator with icon
                  if (item.foodType != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.foodType == FoodType.veg
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.foodType == FoodType.veg
                            ? Icons.eco_outlined
                            : Icons.restaurant_outlined,
                        size: 20,
                        color: item.foodType == FoodType.veg
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  
                  if (item.foodType != null) const SizedBox(width: 12),
                  
                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.styledLabelMedium(
                          context,
                          item.name,
                          weight: FontWeight.w600,
                        ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          AppText.styledBodySmall(
                            context,
                            item.category,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Food type label
                  if (item.foodType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: item.foodType == FoodType.veg
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.foodType == FoodType.veg
                              ? Colors.green[200]!
                              : Colors.red[200]!,
                          width: 1,
                        ),
                      ),
                      child: AppText.styledMetaSmall(
                        context,
                        item.foodType!.label(),
                        weight: FontWeight.w600,
                        color: item.foodType == FoodType.veg
                            ? Colors.green[800]!
                            : Colors.red[800]!,
                      ),
                    ),
                ],
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
