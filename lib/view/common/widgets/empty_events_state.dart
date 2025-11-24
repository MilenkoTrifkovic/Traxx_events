import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/view/admin/create_event_old/create_event_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

/// Empty state widget displayed when no events are created
class EmptyEventsState extends StatelessWidget {
  final VoidCallback? onCreateEvent;

  const EmptyEventsState({
    super.key,
    this.onCreateEvent,
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
              // Welcome heading
              AppText.styledHeadingLarge(
                context,
                'Welcome to TRAX Events!',
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
                      Constants.cartoonRestaurant,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Spacing
              AppSpacing.verticalMd(context),

              // Create first event heading
              AppText.styledHeadingLarge(
                context,
                'Let\'s Create Your First Event.',
              ),

              // Spacing
              AppSpacing.verticalMd(context),

              // Description text
              AppText.styledBodyMedium(
                context,
                'Let\'s get started! Create your first event to begin managing guests, menus, and RSVPs all in one place.',
                textAlign: TextAlign.center,
              ),

              // Spacing
              AppSpacing.verticalMd(context),

              // Add Event button
              AppPrimaryButton(
                text: 'Add Event',
                icon: Icons.add,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return CreateEventPopupView();
                    },
                  );
                  // Handle add event action
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
