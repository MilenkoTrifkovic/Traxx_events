import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';

/// A reusable form widget for adding companion information
/// Used in the RSVP response flow for guests to add their companions
class CompanionFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final RxnString selectedCountry;
  final RxnString selectedState;
  final Rxn<Gender> selectedGender;
  final String? companionNumber;
  final bool readOnly;

  /// ✅ NEW
  final RxBool willAttend;
  final bool attendanceDisabled; // disable chips when inviteByEmail or readOnly
  final bool showAttendanceHint;

  const CompanionFormWidget({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.addressController,
    required this.cityController,
    required this.selectedCountry,
    required this.selectedState,
    required this.selectedGender,
    this.companionNumber,
    this.readOnly = false,

    // ✅ NEW
    required this.willAttend,
    this.attendanceDisabled = false,
    this.showAttendanceHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipsDisabled = readOnly || attendanceDisabled;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (companionNumber != null) ...[
            AppText.styledHeadingSmall(
              context,
              'Companion $companionNumber',
              weight: AppFontWeight.semiBold,
            ),
            const SizedBox(height: 16),
          ],

          // Name (required)
          AppTextInputField(
            label: 'Full Name *',
            controller: nameController,
            hintText: 'Enter companion full name',
            readOnly: readOnly,
            validator: readOnly
                ? null
                : (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
          ),

          // Email (required)
          AppTextInputField(
            label: 'Email Address *',
            controller: emailController,
            hintText: 'Enter companion email address',
            keyboardType: TextInputType.emailAddress,
            readOnly: readOnly,
            validator: readOnly ? null : ValidationHelper.validateEmail,
          ),

          // ✅ NEW: Attendance chips
          const SizedBox(height: 12),
          AttendChips(
            willAttend: willAttend,
            disabled: chipsDisabled,
            showHint: showAttendanceHint,
          ),

          const SizedBox(height: 12),

          // Address (optional)
          AppTextInputField(
            label: 'Address (Optional)',
            controller: addressController,
            hintText: 'Enter street address',
            readOnly: readOnly,
          ),

          // City (optional)
          AppTextInputField(
            label: 'City (Optional)',
            controller: cityController,
            hintText: 'Enter city',
            readOnly: readOnly,
          ),

          // Country dropdown
          Obx(() {
            return AppDropdownMenu<String>(
              label: 'Country (Optional)',
              value: selectedCountry.value,
              hintText: 'Select country',
              enabled: !readOnly,
              enableSearch: true,
              searchExtractor: (country) => country,
              items: USData.countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: readOnly
                  ? null
                  : (String? newValue) {
                      selectedCountry.value = newValue;
                      if (newValue != 'United States') {
                        selectedState.value = null;
                      }
                    },
            );
          }),

          // State dropdown - only for United States
          Obx(() {
            if (selectedCountry.value != 'United States') {
              return const SizedBox.shrink();
            }
            return AppDropdownMenu<String>(
              label: 'State (Optional)',
              value: selectedState.value,
              hintText: 'Select state',
              enabled: !readOnly,
              enableSearch: true,
              searchExtractor: (state) => state,
              items: USData.states.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: readOnly
                  ? null
                  : (String? newValue) => selectedState.value = newValue,
            );
          }),

          // Gender dropdown
          Obx(() {
            return AppDropdownMenu<Gender>(
              value: selectedGender.value,
              label: "Gender (Optional)",
              enabled: !readOnly,
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
              onChanged:
                  readOnly ? null : (value) => selectedGender.value = value,
            );
          }),
        ],
      ),
    );
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

/// ✅ NEW: This is the chips UI
class AttendChips extends StatelessWidget {
  final RxBool willAttend;
  final bool disabled;
  final bool showHint;

  const AttendChips({
    super.key,
    required this.willAttend,
    required this.disabled,
    this.showHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final attending = willAttend.value;

      ChoiceChip chip(String label, bool value) {
        return ChoiceChip(
          selected: attending == value,
          label: Text(label),
          onSelected: disabled ? null : (_) => willAttend.value = value,
        );
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.styledBodyLarge(
              context,
              'Will this companion attend?',
              weight: AppFontWeight.semiBold,
            ),
            if (showHint) ...[
              const SizedBox(height: 6),
              AppText.styledBodySmall(
                context,
                'Companion will confirm attendance via email.',
                color: Colors.grey.shade700,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                chip('Yes', true),
                chip('No', false),
              ],
            ),
          ],
        ),
      );
    });
  }
}
