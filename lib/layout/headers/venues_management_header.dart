import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Venues',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
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
                ).then((value) async {
                  if (value != null && value is bool && value) {
                    try {
                      showLoadingIndicator();
                      await controller.submitForm();
                    } finally {
                      hideLoadingIndicator();
                    }
                  }
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
