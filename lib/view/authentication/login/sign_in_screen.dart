import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';
import 'package:traxx_wepapp/theme/app_font_poppins.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
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
  late final SnackbarMessageController snackbarController;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    snackbarController = Get.find<SnackbarMessageController>();
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

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // responsive card width
        final cardW = w < 520.0
            ? w - 32.0 // phone: full width with side padding
            : (w < 900.0 ? 460.0 : 520.0); // tablet/desktop

        final pad = w < 520 ? 16.0 : 24.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: w < 520 ? 16 : 24,
              vertical: w < 520 ? 18 : 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardW),
              child: PoppinsTheme(
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(w < 520 ? 20 : 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SignInHeader(controller: controller),
                        SignInForm(
                          controller: controller,
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          onSubmit: () => _handleEmailPasswordAuth(controller),
                          onForgotPassword: () =>
                              _handleForgotPassword(controller),
                        ),
                        SignInToggle(
                          controller: controller,
                          onToggle: () => _clearFormAndToggleMode(controller),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Setup all GetX listeners for messages and navigation
  /// Setup all GetX listeners for messages and navigation
  void _setupListeners(SignInController controller, BuildContext context) {
    // use snackbarController initialized in initState
    // Watch for success messages
    ever(controller.successMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          snackbarController.showSuccessMessage(message);
          controller.clearSuccessMessage();
        });
      }
    });

    // Watch for error messages
    ever(controller.errorMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          snackbarController.showErrorMessage(message);
          controller.clearErrorMessage();
        });
      }
    });

    // 🔥 Go to email verification after signup / signin (if not verified)
    ever(controller.shouldNavigateToEmailVerification, (bool shouldNavigate) {
      if (shouldNavigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('UI: Navigating to email verification');
          pushAndRemoveAllRoute(AppRoute.emailVerification, context);
          controller.clearNavigationFlags();
        });
      }
    });

    // 🔥 Go to organisation info after verified signin but no org
    ever(controller.shouldNavigateToOrganisationInfo, (bool shouldNavigate) {
      if (shouldNavigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('UI: Navigating to organisation info form');
          pushAndRemoveAllRoute(
            AppRoute.hostOrganisationInfoForm,
            context,
          );
          controller.clearNavigationFlags();
        });
      }
    });

    // 🔥 Go directly to host events when verified + has org
    ever(controller.shouldNavigateToHostEvents, (bool shouldNavigate) {
      if (shouldNavigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('UI: Navigating to host events');
          pushAndRemoveAllRoute(AppRoute.hostEvents, context);
          controller.clearNavigationFlags();
        });
      }
    });
  }
}
