import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/organisation_form_keys.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/section_header.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';

class SalesPersonRefForm extends StatefulWidget {
  const SalesPersonRefForm({super.key});

  @override
  State<SalesPersonRefForm> createState() => _SalesPersonRefFormState();
}

class _SalesPersonRefFormState extends State<SalesPersonRefForm> {
  late final OrganisationInfoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OrganisationInfoController>();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: OrganisationFormKeys.salesPersonRefFormKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SectionHeader(
              icon: Icons.badge,
              title: 'Sales Representative',
              description: 'Enter your sales representative reference code',
            ),
            const SizedBox(height: 24),

            // Reference Code Field
            AppTextInputField(
              label: 'Reference Code (Optional)',
              controller: controller.refCodeController,
              hintText: 'e.g., PER234',
              validator: (value) {
                // Allow empty (optional field)
                if (value == null || value.trim().isEmpty) {
                  return null;
                }

                // Validate format: 3 letters followed by 3 digits (LLLnnn)
                final refCodeRegex = RegExp(r'^[A-Za-z]{3}\d{3}$');
                if (!refCodeRegex.hasMatch(value.trim())) {
                  return 'Invalid format. Expected: 3 letters + 3 digits (e.g., PER234)';
                }

                return null;
              },
              textCapitalization: TextCapitalization.characters,
            ),

            const SizedBox(height: 12),

            // Validation message
            Obx(() => controller.salesPersonValidationMessage.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          controller.salesPersonFound.value
                              ? Icons.check_circle
                              : Icons.error,
                          size: 16,
                          color: controller.salesPersonFound.value
                              ? AppColors.success
                              : AppColors.inputError,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText.styledBodySmall(
                            context,
                            controller.salesPersonValidationMessage.value,
                            color: controller.salesPersonFound.value
                                ? AppColors.success
                                : AppColors.inputError,
                            weight: AppFontWeight.medium,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),

            AppSpacing.verticalXs(context),

            // Helper text
            AppText.styledBodySmall(
              context,
              'Enter your sales representative reference code in the format: 3 letters + 3 digits (e.g., PER234)',
              color: AppColors.textMuted,
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
