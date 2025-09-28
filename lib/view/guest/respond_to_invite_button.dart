import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/guest_controller.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';

class RespondToInviteButton extends StatelessWidget {
  final GuestController guestController;
  // final Event event;
  const RespondToInviteButton(
      {super.key,
      // required this.event,
      required this.guestController});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: AppPadding.vertical(context, paddingType: Sizes.md),
        decoration: AppDecorations.bottomStickyButtonDecoration(context),
        child: Center(
          child: StyledTextButton(
              onPressed: () {
                pushRoute(AppRoute.guestEventRespond, context,
                    // extra: event, urlParam: event.id);
                    extra: guestController.selectedEvent.value,
                    urlParam: guestController.selectedEvent.value.id);
              },
              text: 'Respond to Invite'),
        ),
      ),
    );
  }
}
