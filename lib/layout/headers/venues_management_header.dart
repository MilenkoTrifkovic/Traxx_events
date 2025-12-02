import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_venue_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

class VenuesManagementHeader extends StatelessWidget {
  VenuesManagementHeader({super.key});
  final VenueScreenController controller = VenueScreenController();
  final VenuesController venuesController = Get.find<VenuesController>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Venues'),
        Row(
          children: [
            // if (ScreenSize.isDesktop(context) == true)
            //   AppSearchInputField(
            //     hintText: 'Search events...',
            //     onChanged: (value) {
            //       eventListController.filterEvents(value);
            //     },
            //   ),
            // AppSpacing.horizontalXs(context),
            AppPrimaryButton(
                icon: Icons.add,
                text: 'Add Venue',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return CreateVenuePopupView(
                        controller: controller,
                        venuesController: venuesController,
                      );
                    },
                  ).then(
                    (value) async {
                      if (value != null && value is bool && value) {
                        try {
                          showLoadingIndicator();
                          final createdVenue = await controller.submitForm();
                          venuesController.addVenue(createdVenue);
                          snackbarMessageController.showSuccessMessage(
                              'Venue created successfully.');
                        } on Exception catch (e) {
                          snackbarMessageController
                              .showErrorMessage('Error creating venue');
                        } finally {
                          hideLoadingIndicator();
                        }
                      } else {}
                    },
                  );
                  // Handle add event action
                }),
            // AppSpacing.horizontalXs(context),
          ],
        )
      ],
    );
  }
}
