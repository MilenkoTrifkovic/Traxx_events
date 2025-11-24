import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';

/// A screen that displays the host's questions management interface.
///
/// This screen will eventually include:
/// - List of all question templates
/// - Create new question functionality
/// - Edit existing questions
/// - Question categories management
/// - RSVP forms management
class HostQuestionsScreen extends StatelessWidget {
  const HostQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.verticalMd(context),

          // Placeholder content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: AppColors.borderHover),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz,
                  size: 64,
                  color: AppColors.secondary,
                ),
                AppSpacing.verticalMd(context),
                AppText.styledHeadingMedium(
                  context,
                  'Questions Coming Soon!',
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalSm(context),
                AppText.styledBodyMedium(
                  context,
                  'Questions management functionality will be available here.\nYou\'ll be able to create custom RSVP forms, survey questions, and manage responses.',
                  textAlign: TextAlign.center,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
