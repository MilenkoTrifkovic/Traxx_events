import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_menu_selection_edit_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/menu_item_selection_card.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Menu Items'),
        backgroundColor: AppColors.primaryAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.cancel(context),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.menuItems.isEmpty) {
          return const Center(
            child: Text('No menu items available'),
          );
        }

        return Column(
          children: [
            // Selection count header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select your meal preferences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${controller.selectedMenuItemIds.length} selected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      )),
                ],
              ),
            ),

            // Menu items list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group by category
                        ...controller.categories.map((category) {
                          final items = controller.menuItemsByCategory[category]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12, top: 8),
                                child: Text(
                                  category,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),

                              // Items in this category
                              ...items.map((item) {
                                return Obx(() => MenuItemSelectionCard(
                                      menuItem: item,
                                      isSelected: controller.isMenuItemSelected(item.menuItemId!),
                                      onToggle: () => controller.toggleMenuItem(item.menuItemId!),
                                    ));
                              }).toList(),

                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () => controller.cancel(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Obx(() => AppPrimaryButton(
                          text: controller.isSaving.value
                              ? 'Saving...'
                              : 'Save Selection',
                          onPressed: controller.isSaving.value
                              ? () {}
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
          ],
        );
      }),
    );
  }
}
