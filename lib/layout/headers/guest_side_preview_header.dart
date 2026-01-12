import 'package:flutter/material.dart';
import 'package:traxx_wepapp/layout/headers/widgets/header_back_button.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

class GuestSidePreviewHeader extends StatelessWidget {
  final String eventId;

  const GuestSidePreviewHeader({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeaderBackButton(
          onTap: () {
            // Navigate back to event details
            pushAndRemoveAllRoute(
              AppRoute.eventDetails,
              context,
              urlParam: eventId,
            );
          },
          text: 'Back to Event Details',
        ),
        AppSecondaryButton(
          text: 'Exit Preview Mode',
          icon: Icons.visibility_off,
          onPressed: () {
            pushAndRemoveAllRoute(
              AppRoute.eventDetails,
              context,
              urlParam: eventId,
            );
          },
        ),
      ],
    );
  }
}

