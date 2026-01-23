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

  late final SnackbarMessageController snackbarController;
  late final SignInController controller;

  final List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();

    snackbarController = Get.isRegistered<SnackbarMessageController>()
        ? Get.find<SnackbarMessageController>()
        : Get.put(SnackbarMessageController(), permanent: true);

    controller = Get.isRegistered<SignInController>()
        ? Get.find<SignInController>()
        : Get.put(SignInController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners(controller, context);
    });
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (!_formKey.currentState!.validate()) return;

    await controller.handleEmailPasswordAuth(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _handleForgotPassword() async {
    await controller.handleForgotPassword(_emailController.text.trim());
  }

  void _clearFormAndToggleMode() {
    controller.toggleSignUpMode();
    controller.usePassword.value = false;
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final cardW = w < 520.0 ? w - 32.0 : (w < 900.0 ? 460.0 : 520.0);

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
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                          onSubmit: _handleEmailPasswordAuth,
                          onForgotPassword: _handleForgotPassword,
                          onToggleMode: _clearFormAndToggleMode,
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

  void _setupListeners(SignInController controller, BuildContext context) {
    _workers.add(ever(controller.successMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          snackbarController.showSuccessMessage(message);
          controller.clearSuccessMessage();
        });
      }
    }));

    _workers.add(ever(controller.errorMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          snackbarController.showErrorMessage(message);
          controller.clearErrorMessage();
        });
      }
    }));

    _workers.add(ever(controller.shouldNavigateToEmailVerification, (bool go) {
      if (go) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.emailVerification, context);
          controller.clearNavigationFlags();
        });
      }
    }));

    _workers.add(ever(controller.shouldNavigateToOrganisationInfo, (bool go) {
      if (go) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.hostOrganisationInfoForm, context);
          controller.clearNavigationFlags();
        });
      }
    }));

    _workers.add(ever(controller.shouldNavigateToHostEvents, (bool go) {
      if (go) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.hostEvents, context);
          controller.clearNavigationFlags();
        });
      }
    }));
  }
}
