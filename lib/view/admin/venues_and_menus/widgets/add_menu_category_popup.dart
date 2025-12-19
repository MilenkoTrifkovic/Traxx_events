import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/menu_category_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

class AddMenuCategoryPopup extends StatelessWidget {
  final MenuCategoryController controller;

  const AddMenuCategoryPopup({
    super.key,
    required this.controller,
  });

  Future<void> _submit(BuildContext context) async {
    try {
      final categoryName = await controller.submitForm();
      if (context.mounted) {
        Navigator.of(context).pop(categoryName);
      }
    } catch (e) {
      debugPrint('Error saving category: $e');
      // Error already shown by controller
    }
  }

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
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                        Icons.category_outlined,
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
                            'Manage Menu Categories',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View, add, or remove custom categories for your menus.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSpacing.verticalLg(context),

                      // Existing categories section
                      _buildExistingCategoriesSection(context),

                      AppSpacing.verticalMd(context),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ADD NEW CATEGORY',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(thickness: 1)),
                        ],
                      ),

                      AppSpacing.verticalMd(context),

                      // Add new category form
                      AppTextInputField(
                        label: 'Category Name *',
                        controller: controller.categoryNameController,
                        hintText: 'e.g., Seasonal Specials, Chef\'s Selection',
                        validator: controller.validateCategoryName,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Note: This category will be available across all menus in your organization.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Add Category button
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => AppPrimaryButton(
                                text: controller.isCreatingCategory.value
                                    ? 'Adding...'
                                    : 'Add Category',
                                isLoading: controller.isCreatingCategory.value,
                                onPressed: controller.isCreatingCategory.value
                                    ? null
                                    : () => _submit(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing Categories',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final categories = controller.getExistingCategories();
          return Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: categories.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No categories yet',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isCustom = controller.isCustomCategory(category);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isCustom
                                  ? AppColors.primaryAccent.withOpacity(0.1)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isCustom ? Icons.label : Icons.label_outline,
                              size: 16,
                              color: isCustom
                                  ? AppColors.primaryAccent
                                  : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: isCustom
                              ? Obx(
                                  () => IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : () {
                                            Dialogs.showConfirmationDialog(
                                              context,
                                              'Are you sure you want to delete "$category"?',
                                              () async {
                                                await controller.deleteCategory(category);
                                              },
                                              additionalExplanation: 'This action cannot be undone.',
                                              title: 'Delete Category',
                                            );
                                          },
                                    tooltip: 'Delete category',
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Built-in',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          );
        }),
      ],
    );
  }
}
