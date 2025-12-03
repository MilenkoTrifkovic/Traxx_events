import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/sign_in_header.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/sign_in_form.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/sign_in_toggle.dart';

//TODO: UI should be redefined for this screen
class SignInScreenWidget extends StatefulWidget {
  const SignInScreenWidget({super.key});

  @override
  State<SignInScreenWidget> createState() => _SignInScreenWidgetState();
}

class _SignInScreenWidgetState extends State<SignInScreenWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailPasswordAuth(SignInController controller) async {
    if (!_formKey.currentState!.validate()) return;

    await controller.handleEmailPasswordAuth(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _handleForgotPassword(SignInController controller) async {
    await controller.handleForgotPassword(_emailController.text.trim());
  }

  void _clearFormAndToggleMode(SignInController controller) {
    controller.toggleSignUpMode();
    // Clear form when switching modes
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(SignInController());

    // Setup listeners for messages and navigation
    _setupListeners(controller, context);

    return SingleChildScrollView(
      child: SizedBox(
        width: 400,
        child: Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                SignInHeader(controller: controller),

                // Form Section
                SignInForm(
                  controller: controller,
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  onSubmit: () => _handleEmailPasswordAuth(controller),
                  onForgotPassword: () => _handleForgotPassword(controller),
                ),

                // Toggle Section
                SignInToggle(
                  controller: controller,
                  onToggle: () => _clearFormAndToggleMode(controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Setup all GetX listeners for messages and navigation
  /// Setup all GetX listeners for messages and navigation
  void _setupListeners(SignInController controller, BuildContext context) {
    // Watch for success messages
    ever(controller.successMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showSuccess(context, message);
          controller.clearSuccessMessage();
        });
      }
    });

    // Watch for error messages
    ever(controller.errorMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showError(context, message);
          controller.clearErrorMessage();
        });
      }
    });

    // ✅ NEW: after login/signup success → always go to host events
    ever(controller.shouldNavigateToHostEvents, (bool shouldNavigate) {
      if (shouldNavigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('UI: Navigating to host events (login/signup success)');
          pushAndRemoveAllRoute(AppRoute.hostEvents, context);
          controller.clearNavigationFlags();
        });
      }
    });

    // We no longer listen for:
    // - shouldNavigateToEmailVerification
    // - shouldNavigateToOrganisationInfo
  }
}
