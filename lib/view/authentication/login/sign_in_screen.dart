import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_poppins.dart';
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
    controller.cancelCurrentAuth(
        silent: true); // ✅ unlock UI if something running
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

                        // ✅ shows cancel bar when auth is in progress
                        Obx(() {
                          if (!controller.isLoading.value) {
                            return const SizedBox.shrink();
                          }
                          final method = controller.activeAuthMethodLabel;
                          final mode = controller.isSignUpMode.value
                              ? 'Signing up'
                              : 'Signing in';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.18)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$mode with $method…',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.cancelCurrentAuth,
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        }),

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
  }
}
