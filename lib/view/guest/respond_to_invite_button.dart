import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/guest_controller.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/view/guest/widgets/guest_responses_modal.dart';

class RespondToInviteButton extends StatelessWidget {
  final GuestController guestController;
  final bool hasResponse;
  const RespondToInviteButton(
      {super.key, required this.guestController, required this.hasResponse});

  final String viewRespond = 'View Response';
  final String respond = 'Respond to Invite';
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.vertical(context, paddingType: Sizes.md),
      decoration: AppDecorations.bottomStickyButtonDecoration(context),
      child: Center(
        child: hasResponse
            ? StyledTextButton(
                onPressed: () async {
                  await GuestResponsesModal.show(context,
                      guestController: guestController,
                      responses: guestController.responses,
                      menuItems: guestController.eventMenus);
                },
                text: viewRespond)
            : guestController.rsvpDeadlineValid()
                ? StyledTextButton(
                    onPressed: () {
                      pushAndRemoveAllRoute(AppRoute.guestEventRespond, context,
                          extra: guestController.selectedEvent.value,
                          urlParam:
                              guestController.selectedEvent.value.eventId);
                    },
                    text: respond)
                : AppText.styledBodyLarge(context,
                    'RSVP Deadline Was ${guestController.rsvpDeadline()}',
                    weight: FontWeight.bold, color: AppColors.error(context)),
      ),
    );
  }
}
