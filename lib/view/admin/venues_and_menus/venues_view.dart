import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_card.dart';

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

  @override
  void initState() {
    super.initState();
    controller = Get.put(VenueScreenController());
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
            onTap: () {
              pushAndRemoveAllRoute(AppRoute.hostVenueDetails, context,
                  urlParam: venue.venueID);
            },
          ),
        );
      },
    );
  }
}
