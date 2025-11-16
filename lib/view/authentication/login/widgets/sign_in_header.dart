import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/sign_in_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class SignInHeader extends StatelessWidget {
  final SignInController controller;

  const SignInHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Logo
        Padding(
          padding: AppPadding.only(
            context,
            paddingType: Sizes.lg,
            bottom: true,
          ),
          child: Image.asset(
            Constants.lightLogo,
            height: 32,
          ),
        ),

        // Title
        Obx(() => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.isSignUpMode.value
                    ? "Create your account"
                    : "Sign in to Trax Events",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            )),

        // Subtitle
        Obx(() => Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                controller.isSignUpMode.value
                    ? "Start organizing amazing events today"
                    : "Welcome back! Please enter your details.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )),
      ],
    );
  }
}
