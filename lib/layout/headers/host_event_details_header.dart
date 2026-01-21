import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/layout/headers/widgets/header_back_button.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

class HostEventDetailsHeader extends StatelessWidget {
  HostEventDetailsHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();
  final SnackbarMessageController snackbarController =
      Get.find<SnackbarMessageController>();
  @override
  Widget build(BuildContext context) {
    bool isDesktop = ScreenSize.isDesktop(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeaderBackButton(
            onTap: () => pushAndRemoveAllRoute(AppRoute.hostEvents, context),
            text: 'Back to Events'),
        Row(
          children: [
            AppSpacing.horizontalXs(context),
            AppPrimaryButton(
              text: isDesktop ? 'Preview Guest Page' : '',
              icon: Icons.remove_red_eye,
              height: 44,
              // slight “glass” look on dark header
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(1),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              onPressed: () {
                final eventId = GoRouterState.of(context)
                    .pathParameters[AppRoute.eventDetails.placeholder];
                if (eventId != null) {
                  pushRoute(AppRoute.guestSidePreview, context,
                      urlParam: eventId);
                }
              },
            ),
            AppSpacing.horizontalXs(context),
            Obx(() {
              final event = eventListController.selectedEvent.value;
              final isPublished = event?.status == EventStatus.published;

              final buttonTextDesktop =
                  isPublished ? 'Re-publish' : 'Publish Event';
              final buttonTextMobile = isPublished ? 'Re-publish' : 'Publish';

              return Row(
                children: [
                  AppSpacing.horizontalXs(context),
                  AppPrimaryButton(
                    text: isDesktop ? buttonTextDesktop : buttonTextMobile,
                    icon: isPublished ? Icons.refresh : Icons.publish,
                    onPressed: () async {
                      try {
                        final eventId = GoRouterState.of(context)
                            .pathParameters[AppRoute.eventDetails.placeholder];

                        if (eventId == null || eventId.trim().isEmpty) {
                          snackbarController
                              .showErrorMessage('Event ID not found.');
                          return;
                        }

                        await eventListController
                            .publishEventById(eventId.trim());

                        if (!context.mounted) return;

                        snackbarController.showSuccessMessage(
                          isPublished
                              ? 'Event re-published successfully!'
                              : 'Event published successfully!',
                        );
                      } catch (e) {
                        print('Error publishing event: $e');
                        if (!context.mounted) return;

                        snackbarController.showErrorMessage(
                          isPublished
                              ? 'Failed to re-publish event. Please try again.'
                              : 'Failed to publish event. Please try again.',
                        );
                      }
                    },
                  ),
                ],
              );
            }),
          ],
        )
      ],
    );
  }
}
