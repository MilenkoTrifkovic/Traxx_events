import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_event_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

class EventListHeader extends StatelessWidget {
  EventListHeader({super.key});

  final EventListController eventListController =
      Get.find<EventListController>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Events'),
        AppPrimaryButton(
          icon: Icons.add,
          text: 'Add Event',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return CreateEventPopupView();
              },
            );
          },
        ),
      ],
    );
  }
}
