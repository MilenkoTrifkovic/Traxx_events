import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class SettingsHeader extends StatelessWidget {
  SettingsHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
