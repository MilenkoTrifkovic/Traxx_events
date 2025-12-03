import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

/// Reusable empty state widget.
///
/// Accepts a [title], [description] (text below the image), an [imageAsset]
/// path (defaults to the app cartoon), a [buttonText] and an [onButtonPressed]
/// callback.
class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String? imageAsset;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
  this.imageAsset,
    required this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heading
              Flexible(
                child: AppText.styledHeadingLarge(
                  context,
                  title,
                  textAlign: TextAlign.center,
                ),
              ),

              // Spacing
              AppSpacing.verticalMd(context),

              // Flexible image that can resize based on available space
              Flexible(
                flex: 3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 680.0,
                    maxHeight: 413.1,
                  ),
                  child: AspectRatio(
                    aspectRatio: 680.0 / 413.1,
                    child: Image.asset(
                      imageAsset ?? Constants.cartoonRestaurant,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Spacing
              AppSpacing.verticalMd(context),

              // Description text
              AppText.styledBodyMedium(
                context,
                description,
                textAlign: TextAlign.center,
              ),

              // Spacing
              AppSpacing.verticalMd(context),

              // Primary action button
              AppPrimaryButton(
                text: buttonText,
                icon: Icons.add,
                onPressed: onButtonPressed,
              ),
            ],
          ),
        );
      },
    );
  }
}
