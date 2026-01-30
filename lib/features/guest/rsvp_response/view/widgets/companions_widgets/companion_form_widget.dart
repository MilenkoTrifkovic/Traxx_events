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

const Color kAccent = Color(0xFF6C4BFF);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color kGfPurple = Color(0xFF673AB7);
const Color gfBackground = Color(0xFFF4F0FB);

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

          const SizedBox(height: 12),

          AttendChips(
            willAttend: willAttend,
            disabled: chipsDisabled,
            showHint: showAttendanceHint,
          ),
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

      Widget segButton({
        required bool value,
        required String label,
        required IconData icon,
      }) {
        final selected = attending == value;

        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled ? null : () => willAttend.value = value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? kGfPurple.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? kGfPurple : kBorder,
                  width: selected ? 1.6 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: kGfPurple.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: disabled
                        ? Colors.grey.shade400
                        : (selected ? kGfPurple : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? Colors.grey.shade400
                          : (selected ? kGfPurple : kTextDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: kGfPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: kGfPurple,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Will this companion attend?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                ),
                if (disabled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'Locked',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),

            if (showHint) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will be confirmed by the companion via email.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Segmented buttons
            Row(
              children: [
                segButton(
                  value: true,
                  label: 'Yes',
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 10),
                segButton(
                  value: false,
                  label: 'No',
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // subtle helper line (optional)
            Text(
              attending ? 'Marked as attending.' : 'Marked as not attending.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? Colors.grey.shade400
                    : (attending ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    });
  }
}
