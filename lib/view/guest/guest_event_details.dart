import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
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
  Future<GuestController>? _guestControllerPromise;
  late GuestController guestController;
  late String eventId;
  EventController eventController = Get.find<EventController>();
  @override
  void initState() {
    super.initState();
    eventId = eventController.selectedEvent.value!.eventId!;
    _guestControllerPromise = Get.putAsync(
      //putAsync to trigger onInit() in Controllers mixin
      () => GuestController.create(eventId, 'GtVe8orzBte68w3YkMKX').then(
        (controller) {
          guestController = controller;
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
          return controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<GuestController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: _guestControllerPromise,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Text('ERROR');
            } else if (snapshot.hasData) {
              // return Obx(() {
              final controller = snapshot.data!; // Get controller from snapshot
              final Event event = controller.selectedEvent.value;
              return _buildEventDetails(event, controller);
              // });
            } else {
              return Text('Default Return');
            }
          },
        )
      ],
    );
  }

  Widget _buildEventDetails(Event event, GuestController guestController) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
          ),
          RespondToInviteButton(
            hasResponse: guestController.responses
                .isNotEmpty, //if responses is empty user didn't respond yet
            guestController: guestController,
          )
        ],
      ),
    );
  }
}
