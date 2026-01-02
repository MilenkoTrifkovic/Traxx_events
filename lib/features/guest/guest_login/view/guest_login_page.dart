import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_login/controllers/guest_login_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
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
  }

  @override
  void dispose() {
    _invitationCodeController.dispose();
    _batchIdController.dispose();
    super.dispose();
  }

  /// Handle form submission
  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    await controller.handleNext(
      invitationCode: _invitationCodeController.text.trim(),
      batchId: _batchIdController.text.trim(),
      context: context,
    );
  }

  /// Handle field changes to validate form
  void _onFieldChanged() {
    controller.validateForm(
      _invitationCodeController.text,
      _batchIdController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: SizedBox.expand(
        child: Padding(
          padding: AppPadding.all(context, paddingType: Sizes.xl),
          child: Row(
            children: [
              // Left Panel - Guest Login Form
              _buildLeftPanel(context),
              // Right Panel - Guest Welcome Content
              _buildRightPanel(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build left panel with login form
  Widget _buildLeftPanel(BuildContext context) {
    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(context),

                      SizedBox(height: AppSpacing.md(context)),

                      // Form Section
                      _buildForm(context),

                      SizedBox(height: AppSpacing.lg(context)),

                      // Next Button
                      _buildNextButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build right panel with welcome message for guests
  Widget _buildRightPanel(BuildContext context) {
    // Only show on desktop/tablet, not on phone
    if (ScreenSize.isPhone(context)) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Padding(
        padding: AppPadding.left(context, paddingType: Sizes.xl),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledHeadingLarge(
                family: Constants.font2,
                weight: FontWeight.bold,
                context,
                'Welcome, Guest!',
                color: AppColors.white,
              ),
              SectionDivider(
                height: 30,
                thickness: 2,
                color: AppColors.white,
              ),
              AppText.styledHeadingMedium(
                weight: FontWeight.bold,
                context,
                'Enter your invitation code to access your personalized event experience',
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with logo and title
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Image.asset(
          Constants.lightLogo,
          height: 32,
        ),

        SizedBox(height: AppSpacing.lg(context)),

        // Title
        AppText.styledHeadingSmall(
          context,
          "Guest Login",
          weight: AppFontWeight.bold,
          color: AppColors.primary,
        ),

        SizedBox(height: AppSpacing.xxxs(context)),

        // Subtitle
        AppText.styledBodyMedium(
          context,
          "Enter your invitation code and batch ID to continue",
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  /// Build form with two input fields
  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        // Invitation Code Field
        AppTextInputField(
          label: 'Invitation Code',
          hintText: 'AB1234CD',
          helperText: 'Format: 2 letters, 4 digits, 2 letters',
          controller: _invitationCodeController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Invitation code is required';
            }
            if (!RegExp(r'^[a-zA-Z]{2}\d{4}[a-zA-Z]{2}$').hasMatch(value.trim())) {
              return 'Invalid format (e.g., AB1234CD)';
            }
            return null;
          },
          onChanged: (_) => _onFieldChanged(),
        ),

        SizedBox(height: AppSpacing.sm(context)),

        // Batch ID Field
        AppTextInputField(
          label: 'Batch ID',
          hintText: '123456',
          helperText: 'Format: 6 digits',
          controller: _batchIdController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
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

  /// Build Next button with loading state
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
