import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_event_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

class EventListHeader extends StatelessWidget {
  EventListHeader({super.key});

  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);

    final isMobile = w < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Events',
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            )),

        // ✅ On mobile keep it compact
        isMobile
            ? IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                      context: context, builder: (_) => CreateEventPopupView());
                },
              )
            : AppPrimaryButton(
                icon: Icons.add,
                text: 'Add Event',
                onPressed: () {
                  showDialog(
                      context: context, builder: (_) => CreateEventPopupView());
                },
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF7C3AED)
                  ], // blue -> violet
                ),
              ),
      ],
    );
  }
}
