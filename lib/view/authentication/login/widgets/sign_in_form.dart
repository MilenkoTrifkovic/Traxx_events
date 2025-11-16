import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';

class SignInForm extends StatelessWidget {
  final SignInController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const SignInForm({
    super.key,
    required this.controller,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Email Field
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

          const SizedBox(height: 16),

          // Password Field
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
                  if (!controller.isSignUpMode.value) {
                    onSubmit();
                  }
                },
              )),

          // Confirm Password Field (only show in sign up mode)
          Obx(() {
            if (controller.isSignUpMode.value) {
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
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                    ),
                    obscureText: !controller.isConfirmPasswordVisible.value,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        ValidationHelper.validateConfirmPassword(
                      value,
                      passwordController.text,
                    ),
                    onFieldSubmitted: (_) {
                      if (controller.isSignUpMode.value) {
                        onSubmit();
                      }
                    },
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          const SizedBox(height: 24),

          // Sign In/Up Button
          Obx(() => SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.isLoading.value ? null : onSubmit,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(controller.isSignUpMode.value
                          ? 'Create account'
                          : 'Sign in'),
                ),
              )),

          // Forgot Password (only show in sign in mode)
          Obx(() {
            if (!controller.isSignUpMode.value) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onForgotPassword,
                    child: Text(
                      'Forgot your password?',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
