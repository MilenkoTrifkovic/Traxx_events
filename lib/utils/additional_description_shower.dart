import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constants.dart';

class AdditionalDescriptionShower {
  static Future<void> showMessage(
    BuildContext context,
    String title,
    List<String> messages,
  ) async {
    if (ScreenSize.isDesktop(context)) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryContainer(context),
          title: AppText.styledHeadingSmall(
            weight: FontWeight.bold,
            family: Constants.font2,
            context,
            title,
            color: AppColors.onSurface(context),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < messages.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  AppText.styledBodyMedium(
                    context,
                    messages[i],
                    color: AppColors.onSurface(context),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: AppText.styledLabelMedium(
                context,
                'Close',
                color: AppColors.primary(context),
              ),
            ),
          ],
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.primaryContainer(context),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledHeadingSmall(
                family: Constants.font2,
                weight: FontWeight.bold,
                context,
                title,
                color: AppColors.onSurface(context),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < messages.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        AppText.styledBodyMedium(
                          context,
                          messages[i],
                          color: AppColors.onSurface(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: AppText.styledLabelMedium(
                    context,
                    'Close',
                    color: AppColors.primary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
