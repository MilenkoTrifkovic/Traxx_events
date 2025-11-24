import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/layout/headers/widgets/header_back_button.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

class HostEventDetailsHeader extends StatelessWidget {
  HostEventDetailsHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeaderBackButton(
            onTap: () => pushAndRemoveAllRoute(AppRoute.hostEvents, context),
            text: 'Back to Events'),
        // AppText.styledHeadingLarge(context, 'Events'),
        Row(
          children: [
            // AppSearchInputField(
            //   hintText: 'Search events...',
            //   onChanged: (value) {
            //     eventListController.filterEvents(value);
            //   },
            // ),

            AppSpacing.horizontalXs(context),
            AppSecondaryButton(
              text: 'Preview Guest Page',
              onPressed: () {},
            ),
            // AppSecondaryButton(text: 'text'),
            AppSpacing.horizontalXs(context),
            AppSecondaryButton(
                text: 'Edit Details', icon: Icons.edit_note, onPressed: () {}),
            AppSpacing.horizontalXs(context),
            AppPrimaryButton(
                // icon: Icons.add,
                text: 'Publish Event',
                onPressed: () {
                  // Handle add event action
                }),
            AppSpacing.horizontalXs(context),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.black,
              ),
              color: AppColors.background(context),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    ///////////////////////////////////////////////ToDo
                    child: Text('Edit Event'),
                    onTap: () {},
                    // onTap: () => hostController.toggleEditingEvent(true),
                  ),
                  PopupMenuItem(
                    ///////////////////////////////////////////////ToDo
                    child: Text('Delete Event'),
                    onTap: () async {
                      Dialogs.showConfirmationDialog(
                        context,
                        "Are you sure you want to delete this event? \nThis action cannot be undone.",
                        () async {
                          try {
                            await eventListController
                                .deleteEvent(); ///////////////////////////////////////////////////
                            if (!context.mounted) return;
                            SnackBarUtils.showSuccess(
                                context, 'Event deleted successfully');
                            popRoute(context);
                          } on Exception catch (e) {
                            print('Error deleting event: $e');
                            SnackBarUtils.showError(
                                context, 'Event deletion failed. Try again');
                          }
                        },
                      );
                    },
                  ),
                ];
              },
            ),
          ],
        )
      ],
    );
  }
}
