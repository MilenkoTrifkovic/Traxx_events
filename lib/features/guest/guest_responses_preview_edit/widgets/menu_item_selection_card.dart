import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Widget for displaying a selectable menu item card
class MenuItemSelectionCard extends StatelessWidget {
  final MenuItem menuItem;
  final bool isSelected;
  final VoidCallback onToggle;

  const MenuItemSelectionCard({
    super.key,
    required this.menuItem,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primaryAccent : AppColors.borderSubtle,
          width: isSelected ? 1.5 : 1,
        ),
        color: isSelected 
            ? AppColors.primaryAccent.withOpacity(0.04)
            : Colors.white,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Compact checkbox
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryAccent : AppColors.borderInput,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Menu item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and price in same row
                    Row(
                      children: [
                        Expanded(
                          child: AppText.styledLabelLarge(
                            context,
                            menuItem.name,
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (menuItem.price != null) ...[
                          const SizedBox(width: 8),
                          AppText.styledLabelMedium(
                            context,
                            '\$${menuItem.price!.toStringAsFixed(2)}',
                            weight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ],
                      ],
                    ),

                    // Description (if exists)
                    if (menuItem.description != null &&
                        menuItem.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AppText.styledBodySmall(
                        context,
                        menuItem.description!,
                        color: AppColors.textMuted,
                      ),
                    ],

                    // Food type badge (compact)
                    if (menuItem.foodType != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            menuItem.foodType == FoodType.veg
                                ? Icons.eco_outlined
                                : Icons.restaurant_outlined,
                            size: 12,
                            color: menuItem.foodType == FoodType.veg
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                          const SizedBox(width: 4),
                          AppText.styledMetaSmall(
                            context,
                            menuItem.foodType!.label(),
                            color: menuItem.foodType == FoodType.veg
                                ? Colors.green[700]!
                                : Colors.red[700]!,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
