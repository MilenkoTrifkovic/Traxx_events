import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/menu_selection_controller.dart';
import 'menu_constants.dart';

/// A header card widget for the menu selection page.
class MenuHeaderCard extends StatelessWidget {
  /// The menu selection controller.
  final MenuSelectionController controller;

  /// Callback when submit is pressed.
  final VoidCallback onSubmit;

  /// Callback when continue is pressed.
  final VoidCallback onContinue;

  const MenuHeaderCard({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: kGfPurple,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        controller.eventName.value.isEmpty
                            ? 'Menu Selection'
                            : controller.eventName.value,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      )),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        controller.companionIndex.value != null
                            ? 'Selecting menu for: ${controller.currentPersonName.value}'
                            : 'Select the items you want.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kTextBody,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Obx(() => SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : (controller.isCurrentPersonDone ? onContinue : onSubmit),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGfPurple,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(controller.buttonText),
          ),
        )),
      ],
    );
  }
}
