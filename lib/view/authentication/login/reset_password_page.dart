import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:url_launcher/url_launcher.dart';

/// Password reset page that handles the oobCode from Firebase password reset link.
/// This page allows hosts to set their initial password after being invited.
class ResetPasswordPage extends StatefulWidget {
  final String oobCode;

  const ResetPasswordPage({
    super.key,
    required this.oobCode,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isVerifying = true;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _email;
  String? _errorMessage;

  // Host portal URL for redirect after success
  static const String _hostPortalUrl = 'https://host.trax-event.app';

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Verify the oobCode to ensure it's valid
  Future<void> _verifyCode() async {
    if (widget.oobCode.isEmpty) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Invalid password reset link. Please request a new one.';
      });
      return;
    }

    try {
      final email = await _auth.verifyPasswordResetCode(widget.oobCode);
      setState(() {
        _isVerifying = false;
        _email = email;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'An error occurred. Please try again or request a new link.';
      });
    }
  }

  /// Handle password reset submission
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      // Redirect to host portal after a short delay
      await Future.delayed(const Duration(seconds: 2));
      _redirectToHostPortal();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  /// Redirect to host portal
  void _redirectToHostPortal() {
    final uri = Uri.parse(_hostPortalUrl);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Get user-friendly error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'expired-action-code':
        return 'This link has expired. Please request a new password reset link.';
      case 'invalid-action-code':
        return 'This link is invalid. Please request a new password reset link.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      default:
        return 'An error occurred. Please try again or request a new link.';
    }
  }

  /// Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Background Image
            _buildBackground(),
            // Transparent color overlay
            _buildOverlay(),
            // Content layer
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/photos/welcome_background.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.primaryAccent.withOpacity(0.6),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: SingleChildScrollView(
          padding: AppPadding.all(context, paddingType: Sizes.xl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.98),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildCardContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    if (_isVerifying) {
      return _buildVerifyingState(context);
    }

    if (_errorMessage != null && _email == null) {
      return _buildErrorState(context);
    }

    if (_isSuccess) {
      return _buildSuccessState(context);
    }

    return _buildResetForm(context);
  }

  Widget _buildVerifyingState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 48,
          width: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        AppText.styledLabelLarge(
          context,
          'Verifying your link...',
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 64,
          color: AppColors.inputError,
        ),
        const SizedBox(height: 24),
        AppText.styledHeadingMedium(
          context,
          'Link Invalid',
          color: AppColors.primary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AppText.styledBodyMedium(
          context,
          _errorMessage!,
          color: AppColors.secondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppText.styledBodySmall(
          context,
          'Please contact your administrator to request a new invitation.',
          color: AppColors.textMuted,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        AppText.styledHeadingMedium(
          context,
          'Password Set Successfully!',
          color: AppColors.primary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AppText.styledBodyMedium(
          context,
          'Your password has been set. You can now close this page and log in to the Host Portal.',
          color: AppColors.secondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Primary button to open Host Portal
        AppPrimaryButton(
          text: 'Open Host Portal',
          onPressed: _redirectToHostPortal,
          icon: Icons.open_in_new,
          height: 52,
        ),
        const SizedBox(height: 16),
        
        // Secondary info text
        AppText.styledBodySmall(
          context,
          'If the button doesn\'t work, copy and paste this link into your browser:',
          color: AppColors.textMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SelectableText(
          _hostPortalUrl,
          style: TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Header
          _buildHeader(context),
          const SizedBox(height: 32),

          // Email display
          if (_email != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 20, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText.styledBodyMedium(
                      context,
                      _email!,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Password field
          AppTextInputField(
            label: 'New Password',
            hintText: 'Enter your new password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}), // Update requirements display
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm password field
          AppTextInputField(
            label: 'Confirm Password',
            hintText: 'Confirm your new password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          const SizedBox(height: 12),

          // Password requirements
          _buildPasswordRequirements(context),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inputError.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 20, color: AppColors.inputError),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText.styledBodySmall(
                      context,
                      _errorMessage!,
                      color: AppColors.inputError,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          AppPrimaryButton(
            text: 'Set Password',
            onPressed: _isLoading ? null : _handleSubmit,
            isLoading: _isLoading,
            height: 52,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            size: 48,
            color: AppColors.primaryAccent,
          ),
        ),
        const SizedBox(height: 24),
        AppText.styledHeadingMedium(
          context,
          'Set Your Password',
          color: AppColors.primary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AppText.styledBodyMedium(
          context,
          'Create a secure password to access the Host Portal',
          color: AppColors.secondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(BuildContext context) {
    final password = _passwordController.text;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledLabelSmall(
            context,
            'Password requirements:',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          _buildRequirement(context, 'At least 8 characters', password.length >= 8),
          _buildRequirement(context, 'One uppercase letter', password.contains(RegExp(r'[A-Z]'))),
          _buildRequirement(context, 'One lowercase letter', password.contains(RegExp(r'[a-z]'))),
          _buildRequirement(context, 'One number', password.contains(RegExp(r'[0-9]'))),
        ],
      ),
    );
  }

  Widget _buildRequirement(BuildContext context, String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          AppText.styledBodySmall(
            context,
            text,
            color: isMet ? AppColors.success : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
