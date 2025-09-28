import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/guest_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/common/event_details/widgets/cover_image.dart';
import 'package:traxx_wepapp/view/common/event_details/widgets/event%20_info_section.dart';
import 'package:traxx_wepapp/view/guest/respond_to_invite_button.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

class GuestEventDetails extends StatefulWidget {
  const GuestEventDetails({
    super.key,
  });

  @override
  State<GuestEventDetails> createState() => _GuestEventDetailsState();
}

class _GuestEventDetailsState extends State<GuestEventDetails> {
  GuestController guestController = Get.put(GuestController());
  @override
  void initState() {
    super.initState();
    ever(
      //Display error messages when they occur
      guestController.errorMessage,
      (String message) {
        if (message.isNotEmpty) {
          SnackBarUtils.showError(context, message);
          guestController.errorMessage.value = ''; // Reset
        }
      },
    );
    // Future.microtask(() async {
    //   //make sure that ever is set before calling setEvent
    //   await guestController.setEvent(widget.eventId, event: widget.event);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Event event = guestController.selectedEvent.value;
      return _buildEventDetails(event);
    });
  }

  Widget _buildEventDetails(Event event) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              //Cover Image and title
              CoverImage(
                eventListController: null,
                event: event,
                showAdminOptions: false,
              ),
              Padding(
                padding: AppPadding.all(context, paddingType: Sizes.lg),
                child: Column(
                  children: [
                    //Event info
                    EventInfoSection(event: event),
                    //
                    SectionDivider(),

                    //Respond to Invite Button
                  ],
                ),
              )
            ],
          ),
        ),
        RespondToInviteButton(
          guestController: guestController,
        )
      ],
    );
  }
}
