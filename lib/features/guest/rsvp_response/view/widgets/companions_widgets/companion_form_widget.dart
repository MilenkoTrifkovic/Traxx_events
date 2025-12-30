import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final bool readOnly; // If true, displays form in read-only mode

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
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show companion number if provided
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
            validator: readOnly ? null : (value) {
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
              items: USData.countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: readOnly ? null : (String? newValue) {
                selectedCountry.value = newValue;
              },
            );
          }),

          // State dropdown
          Obx(() => AppDropdownMenu<String>(
                label: 'State (Optional)',
                value: selectedState.value,
                hintText: 'Select state',
                enabled: !readOnly,
                items: USData.states.map((String state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: readOnly ? null : (String? newValue) {
                  selectedState.value = newValue;
                },
              )),

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
              onChanged: readOnly ? null : (value) {
                selectedGender.value = value;
              },
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
