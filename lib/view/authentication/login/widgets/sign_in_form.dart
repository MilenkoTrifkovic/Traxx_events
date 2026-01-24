import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

class SignInForm extends StatelessWidget {
  final SignInController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onToggleMode;

  const SignInForm({
    super.key,
    required this.controller,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onToggleMode,
  });

  ButtonStyle _hubButtonStyle({bool filled = false}) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
      backgroundColor: filled ? AppColors.primary : Colors.transparent,
      foregroundColor: filled ? Colors.white : AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: ValidationHelper.validateEmail,
          ),
          const SizedBox(height: 18),

          // OAuth + password toggle (always visible)
          Obx(() {
            final isSignUp = controller.isSignUpMode.value;
            final loading = controller.isLoading.value;
            final active = controller.activeAuthMethod
                .value; // 'google'/'microsoft'/'apple'/'password'

            bool canTap(String method) {
              // ✅ only disable the active button while loading
              if (!loading) return true;
              return active !=
                  method; // allow user to pick another (will cancel + start)
            }

            Future<void> safeStart(
                String method, Future<void> Function() fn) async {
              if (!loading) {
                await fn();
                return;
              }

              // ✅ if something is running, cancel first, then start new
              controller.cancelCurrentAuth(silent: true);
              await fn();
            }

            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _hubButtonStyle(filled: true),
                    onPressed: canTap('google')
                        ? () => safeStart('google', controller.signInWithGoogle)
                        : null,
                    child: Text(isSignUp
                        ? 'Sign up with Google'
                        : 'Sign in with Google'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _hubButtonStyle(),
                    onPressed: canTap('microsoft')
                        ? () => safeStart(
                            'microsoft', controller.signInWithMicrosoft)
                        : null,
                    child: Text(isSignUp
                        ? 'Sign up with Microsoft'
                        : 'Sign in with Microsoft'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _hubButtonStyle(),
                    onPressed: canTap('apple')
                        ? () => safeStart('apple', controller.signInWithApple)
                        : null,
                    child: Text(
                        isSignUp ? 'Sign up with Apple' : 'Sign in with Apple'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: _hubButtonStyle(),
                    onPressed: loading && active == 'password'
                        ? null
                        : controller.togglePasswordMethod,
                    child: Text(
                      controller.usePassword.value
                          ? (isSignUp
                              ? 'Hide password sign up'
                              : 'Hide password sign in')
                          : (isSignUp
                              ? 'Sign up with password'
                              : 'Sign in with password'),
                    ),
                  ),
                ),
              ],
            );
          }),

          // Password section expands only if selected
          Obx(() {
            if (!controller.usePassword.value) {
              return const SizedBox(height: 18);
            }

            return Column(
              children: [
                const SizedBox(height: 18),
                Obx(() => TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                      obscureText: !controller.isPasswordVisible.value,
                      textInputAction: controller.isSignUpMode.value
                          ? TextInputAction.next
                          : TextInputAction.done,
                      validator: ValidationHelper.validatePassword,
                      onFieldSubmitted: (_) {
                        if (!controller.isSignUpMode.value) onSubmit();
                      },
                    )),
                Obx(() {
                  if (!controller.isSignUpMode.value)
                    return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isConfirmPasswordVisible.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                        ),
                        obscureText: !controller.isConfirmPasswordVisible.value,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            ValidationHelper.validateConfirmPassword(
                          value,
                          passwordController.text,
                        ),
                        onFieldSubmitted: (_) => onSubmit(),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 18),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: controller.isLoading.value ? null : onSubmit,
                        child: controller.isLoading.value &&
                                controller.activeAuthMethod.value == 'password'
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(controller.isSignUpMode.value
                                ? 'Create account'
                                : 'Sign in'),
                      ),
                    )),
                Obx(() {
                  if (controller.isSignUpMode.value)
                    return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onForgotPassword,
                        child: Text(
                          'Forgot your password?',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 10),
              ],
            );
          }),

          const SizedBox(height: 6),

          // Toggle sign in / sign up
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.isSignUpMode.value
                        ? "Already have an account? "
                        : "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: onToggleMode,
                    child: Text(
                      controller.isSignUpMode.value ? 'Sign in' : 'Sign up',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              )),

          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: () => pushRoute(AppRoute.guestLogin, context),
              child: AppText.styledBodySmall(
                context,
                'Guest login',
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
