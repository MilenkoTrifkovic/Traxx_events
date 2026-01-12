import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_menu_selection_edit_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/menu_item_selection_card.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Page for editing menu selection responses
class GuestMenuSelectionEditPage extends StatefulWidget {
  const GuestMenuSelectionEditPage({super.key});

  @override
  State<GuestMenuSelectionEditPage> createState() => _GuestMenuSelectionEditPageState();
}

class _GuestMenuSelectionEditPageState extends State<GuestMenuSelectionEditPage> {
  late final GuestMenuSelectionEditController controller;
  late final SnackbarMessageController snackbarController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GuestMenuSelectionEditController());
    snackbarController = Get.find<SnackbarMessageController>();

    // Get guestId from navigation extra and initialize controller ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final guestId = extra?['guestId'] as String?;
      controller.initialize(guestId: guestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.menuItems.isEmpty) {
        return Center(
          child: AppText.styledBodyMedium(
            context,
            'No menu items available',
            color: AppColors.textMuted,
          ),
        );
      }

      return Column(
          children: [
            // Compact header with title and counter
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primaryAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText.styledHeadingSmall(
                          context,
                          'Select Your Meals',
                          weight: FontWeight.bold,
                        ),
                      ),
                      // Compact selection counter
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                AppText.styledLabelMedium(
                                  context,
                                  '${controller.selectedMenuItemIds.length}',
                                  weight: FontWeight.w600,
                                  color: AppColors.primaryAccent,
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // Menu items list with compact spacing
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group by category
                          ...controller.categories.map((category) {
                            final items = controller.menuItemsByCategory[category]!;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Compact category header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(category),
                                          color: AppColors.primaryAccent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: AppText.styledLabelLarge(
                                            context,
                                            category,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                        AppText.styledMetaSmall(
                                          context,
                                          '${items.length}',
                                          color: AppColors.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Items in this category
                                  ...items.map((item) {
                                    return Obx(() => MenuItemSelectionCard(
                                          menuItem: item,
                                          isSelected: controller.isMenuItemSelected(item.menuItemId!),
                                          onToggle: () => controller.toggleMenuItem(item.menuItemId!),
                                        ));
                                  }).toList(),
                                ],
                              ),
                            );
                          }).toList(),
                          
                          const SizedBox(height: 80), // Space for floating button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Compact action bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            text: 'Cancel',
                            onPressed: controller.isSaving.value
                                ? null
                                : () => controller.cancel(context),
                            height: 44,
                            borderRadius: 8,
                            enabled: !controller.isSaving.value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Obx(() => AppPrimaryButton(
                                text: controller.isSaving.value
                                    ? 'Saving...'
                                    : 'Save Selection',
                                icon: controller.isSaving.value
                                    ? null
                                    : Icons.check_circle_outline,
                                height: 44,
                                borderRadius: 8,
                                isLoading: controller.isSaving.value,
                                onPressed: controller.isSaving.value
                                    ? null
                                    : () async {
                                        final success = await controller.saveResponses();
                                        if (context.mounted) {
                                          if (success) {
                                            snackbarController.showSuccessMessage(
                                                'Menu selection saved successfully');
                                            Navigator.of(context).pop();
                                          } else {
                                            snackbarController.showErrorMessage(
                                                'Error saving menu selection');
                                          }
                                        }
                                      },
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      });
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('appetizer') || categoryLower.contains('starter')) {
      return Icons.local_dining;
    } else if (categoryLower.contains('main') || categoryLower.contains('entree')) {
      return Icons.restaurant;
    } else if (categoryLower.contains('dessert') || categoryLower.contains('sweet')) {
      return Icons.cake;
    } else if (categoryLower.contains('drink') || categoryLower.contains('beverage')) {
      return Icons.local_cafe;
    } else if (categoryLower.contains('salad')) {
      return Icons.eco;
    }
    return Icons.fastfood;
  }
}
