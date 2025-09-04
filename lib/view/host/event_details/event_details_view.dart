import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/host/create_event/create_edit_event_view.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/cover_image.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/event%20_info_section.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/event_setup_section.dart';
import 'package:traxx_wepapp/view/host/widgets/common/section_devider.dart';

class EventDetailsView extends StatelessWidget {
  const EventDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    HostController hostController = Get.find<HostController>();
    return Obx(() {
      if (hostController.isEditingEvent.value) {
        return CreateEditEventView();
      }
      return SingleChildScrollView(
        child: Column(
          children: [
            //Cover Image and title
            CoverImage(),
            Padding(
              padding: AppPadding.all(context, paddingType: Sizes.lg),
              child: Column(
                children: [
                  //Event info
                  EventInfoSection(),
                  //Menu Section
                  SectionDivider(),
                  EventSetupSection(),
                  SectionDivider(),
                ],
              ),
            )
          ],
        ),
      );
    });
  }
}
