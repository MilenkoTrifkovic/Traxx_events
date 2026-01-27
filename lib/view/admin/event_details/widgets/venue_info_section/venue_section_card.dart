import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/venue_info_section/widgets/venue_photos_section.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/venue_info_section/widgets/venue_location_section.dart';

/// A card widget that displays venue information split into two sections.
///
/// This widget shows:
/// - Left: Venue photos carousel
/// - Right: Venue details and additional information
///
/// Follows the same UI pattern as MenuSelectionCard and DemographicSelectionCard.
class VenueSelectionCard extends StatelessWidget {
  final AdminEventDetailsController controller;

  const VenueSelectionCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ScreenSize.isPhone(context)
          ? _buildPhoneLayout()
          : _buildTabletDesktopLayout(),
    );
  }

  /// Layout for tablet and desktop screens (side by side)
  Widget _buildTabletDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LEFT SECTION - Venue Photos
        Obx(() {
          return Expanded(
            child: controller.venue.value == null
                ? const VenuePhotosSection(venue: null)
                : VenuePhotosSection(venue: controller.venue.value),
          );
        }),

        const SizedBox(width: 24),

        /// RIGHT SECTION - Venue Location
        Obx(() {
          return Expanded(
            child: VenueLocationSection(venue: controller.venue.value),
          );
        }),
      ],
    );
  }

  /// Layout for phone screens (stacked vertically)
  Widget _buildPhoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// TOP SECTION - Venue Photos
        Obx(() {
          return controller.venue.value == null
              ? const VenuePhotosSection(venue: null)
              : VenuePhotosSection(venue: controller.venue.value);
        }),

        const SizedBox(height: 24),

        /// BOTTOM SECTION - Venue Location
        Obx(() {
          return VenueLocationSection(venue: controller.venue.value);
        }),
      ],
    );
  }
}
