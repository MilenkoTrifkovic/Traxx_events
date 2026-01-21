import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/features/guest/guest_login/controllers/guest_login_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_poppins.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/background_scaffold.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

/// Guest Login Page
/// Simple login form with invitation code and email fields
class GuestLoginPage extends StatefulWidget {
  const GuestLoginPage({super.key});

  @override
  State<GuestLoginPage> createState() => _GuestLoginPageState();
}

class _GuestLoginPageState extends State<GuestLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _invitationCodeController = TextEditingController();
  final _batchIdController = TextEditingController();
  late final GuestLoginController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GuestLoginController());

    _invitationCodeController.addListener(_onFieldChanged);
    _batchIdController.addListener(_onFieldChanged);

    _onFieldChanged();
  }

  @override
  void dispose() {
    _invitationCodeController.removeListener(_onFieldChanged);
    _batchIdController.removeListener(_onFieldChanged);
    _invitationCodeController.dispose();
    _batchIdController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    await controller.handleNext(
      invitationCode: _invitationCodeController.text.trim().toUpperCase(),
      batchId: _batchIdController.text.trim(),
      context: context,
    );
  }

  void _onFieldChanged() {
    controller.validateForm(
      _invitationCodeController.text,
      _batchIdController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PoppinsTheme(
      child: BackgroundScaffold(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final isPhone = w < 900;

            final outerPad = w < 520 ? 16.0 : (w < 1200 ? 24.0 : 32.0);
            final cardMaxW = w < 520 ? w : (w < 900 ? 460.0 : 420.0);

            if (isPhone) {
              // ✅ Phone: only form card, centered
              return SizedBox.expand(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(outerPad),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxW),
                      child: _buildFormCard(context, pad: w < 520 ? 20 : 28),
                    ),
                  ),
                ),
              );
            }

            // ✅ Tablet/Desktop: two panels
            return SizedBox.expand(
              child: Padding(
                padding: EdgeInsets.all(outerPad),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildFormCard(context, pad: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 7,
                      child: _buildRightPanel(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required double pad}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: AppSpacing.md(context)),
              _buildForm(context),
              SizedBox(height: AppSpacing.lg(context)),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    return Padding(
      padding: AppPadding.left(context, paddingType: Sizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Guest!',
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SectionDivider(
            height: 30,
            thickness: 2,
            color: AppColors.white,
          ),
          Text(
            'Enter your invitation code to access your personalized event experience',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(Constants.lightLogo, height: 32),
        SizedBox(height: AppSpacing.lg(context)),
        Text(
          "Guest Login",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: AppSpacing.xxxs(context)),
        Text(
          "Enter your invitation code and batch ID to continue",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        AppTextInputField(
          label: 'Invitation Code',
          hintText: '9MTYJ7V5',
          helperText: 'Format: 8 characters (A–Z, 0–9)',
          controller: _invitationCodeController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
          width: double.infinity, // ✅ allow full width on small screens
          validator: (value) {
            final v = (value ?? '').trim().toUpperCase();
            if (v.isEmpty) return 'Invitation code is required';
            if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(v)) {
              return 'Invalid format (e.g., 9MTYJ7V5)';
            }
            return null;
          },
          onChanged: (_) => _onFieldChanged(),
        ),
        SizedBox(height: AppSpacing.sm(context)),
        AppTextInputField(
          label: 'Batch ID',
          hintText: '123456',
          helperText: 'Format: 6 digits',
          controller: _batchIdController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          width: double.infinity, // ✅ allow full width on small screens
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Batch ID is required';
            }
            if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
              return 'Must be exactly 6 digits';
            }
            return null;
          },
          onChanged: (_) => _onFieldChanged(),
          onFieldSubmitted: (_) => _handleNext(),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Obx(
      () => AppPrimaryButton(
        text: 'Next',
        onPressed: _handleNext,
        width: double.infinity,
        isLoading: controller.isLoading.value,
        enabled: controller.isFormValid.value,
      ),
    );
  }
}
