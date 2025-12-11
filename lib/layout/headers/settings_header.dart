import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class SettingsHeader extends StatelessWidget {
  SettingsHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Settings'),
      ],
    );
  }
}
