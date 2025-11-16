import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class WelcomeBackground extends StatelessWidget {
  const WelcomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/photos/welcome_background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Transparent color overlay
        Positioned.fill(
          child: Container(
            color: AppColors.primaryAccent.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
