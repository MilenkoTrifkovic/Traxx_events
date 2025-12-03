import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/menus_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/dialog_step_header.dart';

class CreateMenuPopupView extends StatelessWidget {
  final MenusScreenController controller;
  const CreateMenuPopupView({super.key, required this.controller});
  // final VenueScreenController controller = VenueScreenController();
  // final VenuesController venuesController = Get.find<VenuesController>();
  @override
  Widget build(BuildContext context) {
    return AppDialog(
        content: SingleChildScrollView(
      child: Padding(
        padding: AppPadding.symmetric(
          context,
          horizontalPadding: Sizes.xxxl, // 64px on desktop
          verticalPadding: Sizes.xl, // 48px on desktop
        ),
        child: Column(
          children: [
            DialogStepHeader(
                icon: Icons.restaurant_menu_outlined,
                title: 'Create Menu Item',
                description: 'Let\'s create a new menu item.'),
            _buildMenuForm(context)
          ],
        ),
      ),
    ));
  }

  Widget _buildMenuForm(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalLg(context),

            // Menu Name Field
            AppTextInputField(
              label: 'Menu Item Name *',
              controller: controller.nameController,
              hintText: 'Enter menu item name',
              validator: controller.validateName,
              // maxLength: 100,
            ),

            // Category dropdown
            Obx(() {
              // return DropdownButtonFormField<MenuCategory>(
              return AppDropdownMenu<MenuCategory>(
                value: controller.selectedCategory.value ?? MenuCategory.other,
                label: "Category *",
                // decoration: const InputDecoration(labelText: 'Category *'),
                items: MenuCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: AppText.styledBodyLarge(
                              context, c.name.capitalize!,
                              weight: AppFontWeight.semiBold),
                        ))
                    .toList(),
                onChanged: (v) => controller.selectedCategory.value = v,
                validator: (v) => v == null ? 'Category is required' : null,
              );
            }),

            // Description Field
            AppTextInputField(
              label: 'Description (Optional)',
              controller: controller.descriptionController,
              hintText: 'Enter venue description',
              maxLines: 3,
              validator: controller.validateDescription,
              // maxLength: 500,
            ),

            // Image Upload Section
            _buildImageUploadSection(context),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Obx(() => AppPrimaryButton(
                        text: controller.isCreatingMenuItem.value
                            ? 'Creating...'
                            : 'Create Menu Item',
                        isLoading: controller.isCreatingMenuItem.value,
                        onPressed: controller.isCreatingMenuItem.value
                            ? null
                            : () async {
                                if (!controller.validateForm()) return;
                                popRoute(context, true);
                              },
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          if (controller.selectedImage.value != null) {
            return _buildSelectedImage(context);
          } else {
            return AppSecondaryButton(
                width: double.infinity,
                icon: Icons.file_upload,
                iconColor: AppColors.primaryAccent,
                textColor: AppColors.primaryAccent,
                text: 'Upload Menu Photo',
                onPressed: controller.pickImage);
          }
        }),
        AppSpacing.verticalSm(context),

        // Image error display
        Obx(() {
          if (controller.imageError.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                controller.imageError.value!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// Builds the selected image preview
  Widget _buildSelectedImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.borderHover),
      ),
      child: Stack(
        children: [
          //     // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: FutureBuilder<Uint8List>(
              future: controller.selectedImage.value!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 360,
                    ),
                    child: Image.memory(
                      snapshot.data!,
                      width: 360,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 360,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ),

          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: controller.removeImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
