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

class AddGuestPopup extends StatefulWidget {
  final AdminGuestListController controller;
  final bool isEditMode;
  final int maxInviteByGuest;

  const AddGuestPopup({
    super.key,
    required this.controller,
    this.isEditMode = false,
    this.maxInviteByGuest = 0,
  });

  @override
  State<AddGuestPopup> createState() => _AddGuestPopupState();
}

class _AddGuestPopupState extends State<AddGuestPopup> {
  bool _isSubmitting = false;

  AdminGuestListController get controller => widget.controller;
  bool get isEditMode => widget.isEditMode;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      content: Stack(
        children: [
          SingleChildScrollView(
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
                  _buildGuestForm(context),
                ],
              ),
            ),
          ),
          // Close button (X) in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, size: 24),
              tooltip: 'Close',
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestForm(BuildContext context) {
    final primaryLabel = _isSubmitting
        ? (isEditMode ? 'Updating...' : 'Adding...')
        : (isEditMode ? 'Update Guest' : 'Add Guest');

    return SizedBox(
      width: double.infinity,
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name (required)
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

            // Email (required)
            AppTextInputField(
              label: 'Email Address *',
              controller: controller.email,
              hintText: 'Enter guest email address',
              keyboardType: TextInputType.emailAddress,
              validator: ValidationHelper.validateEmail,
            ),

            // Max Guest Invite dropdown
            if (widget.maxInviteByGuest > 0)
              Obx(() {
                return AppDropdownMenu<int>(
                  value: controller.maxGuestInvite.value,
                  label: "Max Guest Invite (Optional)",
                  hintText: "Select max guests to invite",
                  items: List.generate(
                    widget.maxInviteByGuest + 1,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: AppText.styledBodyLarge(
                        context,
                        index == 0 ? 'None' : '$index',
                        weight: AppFontWeight.regular,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      controller.maxGuestInvite.value = value;
                    }
                  },
                );
              }),

            // Address (optional)
            AppTextInputField(
              label: 'Address (Optional)',
              controller: controller.address,
              hintText: 'Enter street address',
            ),

            // City (optional)
            AppTextInputField(
              label: 'City (Optional)',
              controller: controller.city,
              hintText: 'Enter city',
            ),

            // Country dropdown
            Obx(() {
              return AppDropdownMenu<String>(
                label: 'Country',
                value: controller.selectedCountry.value,
                hintText: 'Select country',
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

            // State dropdown
            Obx(() => AppDropdownMenu<String>(
                  label: 'State',
                  value: controller.selectedState.value,
                  hintText: 'Select state',
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

            // Gender dropdown
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
                  controller.selectedGender.value = value;
                },
              );
            }),

            AppSpacing.verticalSm(context),

            // Status toggle (Enabled by default)
            Obx(() {
              final enabled = !controller.isDisabled.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.styledBodyLarge(context, 'Status',
                          weight: AppFontWeight.semiBold),
                      const SizedBox(height: 4),
                      AppText.styledBodyMedium(
                          context, enabled ? 'Enabled' : 'Disabled'),
                    ],
                  ),

                  // Switch reflects "Enabled" state (true when not disabled)
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) {
                      controller.isDisabled.value = !val;
                    },
                  ),
                ],
              );
            }),

            AppSpacing.verticalSm(context),

            // Buttons row
            Row(
              children: [
                // Cancel button: always visible (for both add & edit modes),
                // disabled while submitting.
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            // Close dialog and signal "no change"
                            Navigator.of(context).pop(false);
                          },
                    text: 'Cancel',
                  ),
                ),

                // spacing between buttons
                AppSpacing.horizontalMd(context),

                // Primary button (Add / Update). Disabled while submitting.
                Expanded(
                  child: AppPrimaryButton(
                    onPressed:
                        _isSubmitting ? null : () => _onPrimaryPressed(context),
                    text: primaryLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPrimaryPressed(BuildContext context) async {
    // Prevent double taps
    if (_isSubmitting) return;

    // Validate first
    if (!controller.validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    bool success = false;

    try {
      if (isEditMode) {
        success = await controller.updateGuest();
      } else {
        success = await controller.submitForm();
      }
    } catch (e, st) {
      debugPrint('AddGuestPopup submit error: $e\n$st');
      success = false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;

    if (success) {
      // Clear form in controller (caller also commonly clears, but keep it here)
      controller.clearForm();

      // Close dialog and show success
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditMode ? 'Guest updated' : 'Guest added')),
      );
    } else {
      // Keep dialog open and show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode
              ? 'Failed to update guest — try again'
              : 'Failed to add guest — try again'),
        ),
      );
    }
  }

  String _formatGenderName(String genderName) {
    return genderName
        .split(RegExp(r'(?=[A-Z])|_'))
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
