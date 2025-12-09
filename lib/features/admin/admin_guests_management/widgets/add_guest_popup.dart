import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/dialog_step_header.dart';

class AddGuestPopup extends StatelessWidget {
  final AdminGuestListController controller;
  final bool isEditMode;
  const AddGuestPopup(
      {super.key, required this.controller, this.isEditMode = false});

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
                icon: Icons.person_add,
                title: isEditMode ? 'Edit Guest' : 'Add Guest',
                description: isEditMode
                    ? 'Update the guest\'s information.'
                    : 'Fill in the guest information below.',
              ),
              _buildGuestForm(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestForm(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppSpacing.verticalLg(context),

            // Required fields section

            // Name Field (Required)
            AppTextInputField(
              label: 'Full Name *',
              controller: controller.name,
              hintText: 'Enter guest full name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            // AppSpacing.verticalMd(context),

            // Email Field (Required)
            AppTextInputField(
              label: 'Email Address *',
              controller: controller.email,
              hintText: 'Enter guest email address',
              keyboardType: TextInputType.emailAddress,
              validator: ValidationHelper.validateEmail,
            ),
            // AppSpacing.verticalLg(context),

            // Optional fields section
            // AppText.styledBodyLarge(
            //   context,
            //   'Optional Information',
            //   weight: AppFontWeight.semiBold,
            // ),
            // AppSpacing.verticalMd(context),

            // Address Field (Optional)
            AppTextInputField(
              label: 'Address (Optional)',
              controller: controller.address,
              hintText: 'Enter street address',
            ),
            // AppSpacing.verticalMd(context),

            // City Field (Optional)
            AppTextInputField(
              label: 'City (Optional)',
              controller: controller.city,
              hintText: 'Enter city',
            ),
            // AppSpacing.verticalMd(context),

            // Country Dropdown (Optional)
            Obx(() {
              return AppDropdownMenu<String>(
                label: 'Country',
                value: controller.selectedCountry.value,
                hintText: 'Select country',
                // validator: (value) =>
                //     ValidationHelper.validateDropdownSelection(
                // value, 'country'),
                items: USData.countries.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedCountry.value = newValue;
                  }
                },
              );
            }),
            Obx(() => AppDropdownMenu<String>(
                  label: 'State',
                  value: controller.selectedState.value,
                  hintText: 'Select state',
                  // validator: (value) =>
                  //     ValidationHelper.validateDropdownSelection(
                  //         value, 'state'),
                  items: USData.states.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.selectedState.value = newValue;
                    }
                  },
                )),
            // Gender Dropdown (Optional)
            Obx(() {
              return AppDropdownMenu<Gender>(
                value: controller.selectedGender.value,
                label: "Gender (Optional)",
                items: Gender.values
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: AppText.styledBodyLarge(
                            context,
                            _formatGenderName(gender.name),
                            weight: AppFontWeight.regular,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedGender.value = value;
                  }
                },
              );
            }),
            // AppSpacing.verticalLg(context),

            // Action Buttons
            AppSpacing.verticalSm(context),
            Row(
              children: [
                if (isEditMode) ...[
                  Expanded(
                    child: AppSecondaryButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      text: 'Cancel',
                    ),
                  ),
                ],
                if (isEditMode) AppSpacing.horizontalMd(context),
                Expanded(
                  child: AppPrimaryButton(
                    text: isEditMode ? 'Update Guest' : 'Add Guest',
                    onPressed: () async {
                      if (!controller.validateForm()) return;

                      try {
                        if (isEditMode) {
                          await controller.updateGuest();
                        } else {
                          await controller.submitForm();
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        // Error handling is done in controller
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatGenderName(String genderName) {
    // Convert snake_case or camelCase to Title Case
    return genderName
        .split(RegExp(r'(?=[A-Z])|_'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
