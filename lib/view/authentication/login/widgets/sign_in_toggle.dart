import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';

class SignInToggle extends StatelessWidget {
  final SignInController controller;
  final VoidCallback onToggle;

  const SignInToggle({
    super.key,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                controller.isSignUpMode.value
                    ? "Already have an account? "
                    : "Don't have an account? ",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: onToggle,
              child: Text(
                controller.isSignUpMode.value ? 'Sign in' : 'Sign up',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ));
  }
}
