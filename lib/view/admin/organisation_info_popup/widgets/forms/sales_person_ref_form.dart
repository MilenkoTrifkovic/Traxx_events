import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return _PoppinsScope(
      child: Form(
        key: OrganisationFormKeys.salesPersonRefFormKey,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: _responsiveFormMaxWidth(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.badge,
                  title: 'Sales Representative',
                  description: 'Enter your sales representative reference code',
                ),
                const SizedBox(height: 20),

                // Reference Code Field
                AppTextInputField(
                  label: 'Reference Code (Optional)',
                  controller: controller.refCodeController,
                  hintText: 'e.g., PER234',
                  width: double.infinity, // ✅ full width
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final refCodeRegex = RegExp(r'^[A-Za-z]{3}\d{3}$');
                    if (!refCodeRegex.hasMatch(value.trim())) {
                      return 'Invalid format. Expected: 3 letters + 3 digits (e.g., PER234)';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),

                const SizedBox(height: 10),

                // Validation message
                Obx(() {
                  final msg = controller.salesPersonValidationMessage.value;
                  if (msg.isEmpty) return const SizedBox.shrink();

                  final ok = controller.salesPersonFound.value;
                  final c = ok ? AppColors.success : AppColors.inputError;

                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          ok ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: c,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            msg,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),

                Text(
                  'Enter your sales representative reference code in the format: 3 letters + 3 digits (e.g., PER234)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoppinsScope extends StatelessWidget {
  final Widget child;
  const _PoppinsScope({required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          labelStyle: GoogleFonts.poppins(),
          hintStyle: GoogleFonts.poppins(),
          floatingLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(),
        child: child,
      ),
    );
  }
}

double _responsiveFormMaxWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return double.infinity; // phone: full width
  if (w < 1100) return 520; // tablet
  return 720; // desktop
}
