import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/menu_selection_controller.dart';
import 'menu_constants.dart';

/// A progress banner widget showing menu selection progress for companions.
class MenuProgressBanner extends StatelessWidget {
  /// The menu selection controller.
  final MenuSelectionController controller;

  const MenuProgressBanner({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasCompanions) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kGfPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kGfPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant_menu, color: kGfPurple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.fillingForLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kGfPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Person ${controller.currentPersonNumber} of ${controller.totalPeople} • ${controller.completedMenuCount} completed',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: kTextBody,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kGfPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.completedMenuCount + (controller.isCurrentPersonDone ? 0 : 1)} / ${controller.totalPeople}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
