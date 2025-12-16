import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';

class CreateMenuPopupView extends StatelessWidget {
  final MenusScreenController controller;
  const CreateMenuPopupView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      content: SingleChildScrollView(
        child: Container(
          width: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryAccent,
                      AppColors.primaryAccent.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Menu Set',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Give this menu set a name and optional description & cover photo.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: AppPadding.symmetric(
                  context,
                  horizontalPadding: Sizes.xxxl,
                  verticalPadding: Sizes.xl,
                ),
                child: _buildMenuForm(context),
              ),
            ],
          ),
        ),
      ),
    );
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

            // Menu Set Name
            AppTextInputField(
              label: 'Menu Set Name *',
              controller: controller.nameController,
              hintText: 'Enter menu set name (e.g. Wedding Dinner Menu)',
              validator: controller.validateName,
            ),

            AppSpacing.verticalMd(context),

            // Description
            AppTextInputField(
              label: 'Description (Optional)',
              controller: controller.descriptionController,
              hintText: 'Describe when or how this menu set will be used',
              maxLines: 3,
              validator: controller.validateDescription,
            ),

            AppSpacing.verticalMd(context),

            // Image upload
            _buildImageUploadSection(context),

            const SizedBox(height: 24),

            // Create button
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => AppPrimaryButton(
                      text: controller.isCreatingMenu.value
                          ? 'Creating...'
                          : 'Create Menu Set',
                      isLoading: controller.isCreatingMenu.value,
                      onPressed: controller.isCreatingMenu.value
                          ? null
                          : () {
                              if (!controller.validateForm()) return;
                              // let the calling page actually call submitForm()
                              popRoute(context, true);
                            },
                    ),
                  ),
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
              text: 'Upload Menu Set Cover Photo (Optional)',
              onPressed: controller.pickImage,
            );
          }
        }),
        AppSpacing.verticalSm(context),
        Obx(() {
          if (controller.imageError.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                controller.imageError.value!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildSelectedImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.borderHover),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: FutureBuilder<Uint8List>(
              future: controller.selectedImage.value!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
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
