import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_venue_popup_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_card.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_details_dialog.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';

/// A screen that displays the venue management interface.
///
/// This screen includes:
/// - Venue list display
class VenuesView extends StatefulWidget {
  const VenuesView({super.key});

  @override
  State<VenuesView> createState() => _VenuesViewState();
}

class _VenuesViewState extends State<VenuesView> {
  late VenueScreenController controller;
  late final SnackbarMessageController snackbarMessageController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VenueScreenController());
    snackbarMessageController = Get.find<SnackbarMessageController>();
  }

  // Access the global VenuesController
  final venuesController = Get.find<VenuesController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVenuesListSection(context, venuesController),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the venue creation form

  /// Builds the horizontal list of venue cards
  Widget _buildVenuesListSection(
      BuildContext context, VenuesController venuesController) {
    return Obx(() {
      if (venuesController.venues.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height -
              200, // Give it most of the screen height
          child: EmptyState(
            title: 'Create your first venue',
            imageAsset: Constants.cartoonRestaurant,
            description: 'Create your first venue by tapping the button below.',
            buttonText: 'Add First Venue',
            onButtonPressed: () {
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
                      snackbarMessageController
                          .showSuccessMessage('Venue created successfully.');
                    } on Exception catch (e) {
                      snackbarMessageController
                          .showErrorMessage('Error creating venue');
                    } finally {
                      hideLoadingIndicator();
                    }
                  } else {}
                },
              );
            },
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: venuesController.venues.length,
        itemBuilder: (context, index) {
          final venue = venuesController.venues[index];
          return Padding(
            padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
            child: VenueCard(
              venue: venue,
              onDelete: () {
                // Call the delete method from the controller
                venuesController.removeVenue(venue.venueID!);
              },
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return VenueDetailsDialog(venue: venue);
                    });
                // pushAndRemoveAllRoute(AppRoute.hostVenueDetails, context,
                //     urlParam: venue.venueID);
              },
            ),
          );
        },
      );
    });
  }
}
