import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/widgets/buttons/styled_back_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({super.key});

  @override
  Widget build(BuildContext context) {
    HostController hostController = Get.find<HostController>();
    String? eventImage =
        hostController.selectedEvent.value?.coverImageDownloadUrl;
    String defaultImage = Constants.lightLogo;
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
      Positioned(
        top: MediaQuery.of(context).size.height * 0.02, // 2% from bottom
        left: MediaQuery.of(context).size.width * 0.02,
        child: const StyledBackButton(),
      ),
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
            child: AppText.styledHeadingMedium(
                context, hostController.selectedEvent.value!.name,
                color: AppColors.onBackground(context),
                family: Constants.font2,
                weight: FontWeight.bold),
          ),
        ),
      ),
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
                  child: Text('Edit Event'),
                  onTap: () => hostController.toggleEditingEvent(true),
                ),
                PopupMenuItem(
                  child: Text('Delete Event'),
                  onTap: () async {
                    Dialogs.showConfirmationDialog(
                      context,
                      "Are you sure you want to delete this event? \nThis action cannot be undone.",
                      () async {
                        try {
                          await hostController.deleteEvent();
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
        ),
      )
    ]);
  }
}
