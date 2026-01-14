import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/menu_selection_controller.dart';
import 'package:traxx_wepapp/widgets/modals/image_viewer_modal.dart';
import 'menu_constants.dart';
import 'food_type_icon.dart';

/// A card widget displaying a menu item with selection capability.
class MenuItemCardWidget extends StatelessWidget {
  /// The menu item to display.
  final MenuItemDto item;

  /// The menu selection controller.
  final MenuSelectionController controller;

  /// Whether the card is in read-only mode (no selection).
  final bool readOnly;

  const MenuItemCardWidget({
    super.key,
    required this.item,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.isSelected(item.id);

      final foodTypeLabel = item.isVeg == true
          ? 'Veg'
          : item.isVeg == false
              ? 'Non-Veg'
              : (item.foodType ?? '');

      final subtitle = foodTypeLabel.isEmpty
          ? item.categoryLabel
          : '$foodTypeLabel • ${item.categoryLabel}';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MenuSelectableTile(
          title: item.name,
          subtitle: subtitle,
          description: item.description,
          isVeg: item.isVeg,
          selected: selected,
          readOnly: readOnly,
          onTap: () => controller.toggleItem(item.id),
        ),
      );
    });
  }
}

class MenuSelectableTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final bool? isVeg;
  final bool selected;
  final bool readOnly;
  final VoidCallback? onTap;

  const MenuSelectableTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.description = '',
    required this.isVeg,
    required this.selected,
    required this.readOnly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = isVeg == true
        ? Colors.green.shade50
        : isVeg == false
            ? Colors.red.shade50
            : Colors.grey.shade50;

    final Color border = isVeg == true
        ? Colors.green.shade400
        : isVeg == false
            ? Colors.red.shade400
            : kBorder;

    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.white : (selected ? tint : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: readOnly ? kBorder : (selected ? border : kBorder),
          width: readOnly ? 1 : (selected ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: readOnly ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                FoodTypeIcon(isVeg: isVeg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: kTextDark,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: kTextBody,
                          ),
                        ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: kTextBody.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // ✅ right-side selection indicator (same as ungrouped)
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? border : Colors.transparent,
                      border: Border.all(
                        color: selected ? border : kBorder,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a placeholder widget for when image is not available
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.restaurant_menu,
        size: 30,
        color: Colors.grey.shade400,
      ),
    );
  }

  /// Shows the image in a full-screen viewer dialog
  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => ImageViewerModal(imageUrl: imageUrl),
    );
  }
}
