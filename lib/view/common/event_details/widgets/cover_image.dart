import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/widgets/buttons/styled_back_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

class CoverImage extends StatelessWidget {
  final EventListController? eventListController;
  final Event event;
  final bool showAdminOptions; // Whether to show edit/delete buttons
  CoverImage(
      {super.key,
      required this.eventListController,
      required this.event,
      required this.showAdminOptions});

  // Single lookup for snackbar controller in this stateless widget
  final SnackbarMessageController snackbarController =
      Get.find<SnackbarMessageController>();

  @override
  Widget build(BuildContext context) {
    HostController hostController = Get.find<HostController>();

    String? eventImage = event.coverImageDownloadUrl;

    String defaultImage = ConstantsOld.lightLogo;
    return Stack(children: [
      Container(
        width: double.infinity,
        height:
            MediaQuery.of(context).size.height * 0.3, // 30% of screen height
        decoration: BoxDecoration(
          image: DecorationImage(
            image: eventImage != null
                ? NetworkImage(eventImage)
                : Image.asset(defaultImage).image,
            fit: BoxFit.cover,
          ),
        ),
      ),
      // Back button
      Positioned(
        top: MediaQuery.of(context).size.height * 0.02, // 2% from bottom
        left: MediaQuery.of(context).size.width * 0.02,
        child: const StyledBackButton(),
      ),
      // Event title
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.02, // 2% from bottom
        left: MediaQuery.of(context).size.width * 0.02,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
            color: AppColors.background(context).withValues(alpha: 0.9),
          ),
          child: Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.sm),
            child: AppText.styledHeadingMedium(context, event.name,
                color: AppColors.onBackground(context),
                family: ConstantsOld.font2,
                weight: FontWeight.bold),
          ),
        ),
      ),
      // Edit and delete buttons
      if (showAdminOptions)
        Positioned(
          right: 20,
          top: 20,
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.background(context).withValues(alpha: 0.9),
                shape: BoxShape.circle),
            child: PopupMenuButton(
              color: AppColors.background(context),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    ///////////////////////////////////////////////ToDo
                    child: Text('Edit Event'),
                    onTap: () => hostController.toggleEditingEvent(true),
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
                                        await eventListController!
                                            .deleteEvent(); ///////////////////////////////////////////////////
                          if (!context.mounted) return;
                          snackbarController.showSuccessMessage('Event deleted successfully');
                            popRoute(context);
                          } on Exception catch (e) {
                            print('Error deleting event: $e');
                          snackbarController.showErrorMessage('Event deletion failed. Try again');
                          }
                        },
                      );
                    },
                  ),
                ];
              },
            ),
          ),
        )
    ]);
  }
}
