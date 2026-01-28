import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/payment_history_controller.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_event_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

class EventListHeader extends StatelessWidget {
  EventListHeader({super.key});

  final EventListController eventListController =
      Get.find<EventListController>();

  /// Get PaymentHistoryController safely
  PaymentHistoryController? get _paymentHistoryController {
    try {
      return Get.find<PaymentHistoryController>();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);

    final isMobile = w < 600;

    return Obx(() {
      // Reactive values - triggers rebuild when these change
      final purchased = _paymentHistoryController?.totalPurchasedEvents.value ?? 0;
      final gifted = _paymentHistoryController?.totalGiftedEvents.value ?? 0;
      // Use eventListController.events which is updated when events are created
      final used = eventListController.events.length;
      // Include both purchased AND gifted events in remaining calculation
      final remaining = (purchased + gifted) - used;
      final canCreate = remaining > 0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title with remaining events badge
          Row(
            children: [
              Text(
                'Events',
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              // Remaining events badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: remaining > 0
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: remaining > 0
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      remaining > 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      size: 16,
                      color: remaining > 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$remaining event${remaining == 1 ? '' : 's'} left',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: remaining > 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Add Event button (disabled when no events left)
          isMobile
              ? IconButton(
                  icon: Icon(
                    Icons.add,
                    color: canCreate ? null : Colors.grey,
                  ),
                  onPressed: canCreate
                      ? () {
                          showDialog(
                            context: context,
                            builder: (_) => CreateEventPopupView(),
                          );
                        }
                      : null,
                  tooltip: canCreate ? 'Add Event' : 'No events remaining',
                )
              : AppPrimaryButton(
                  icon: Icons.add,
                  text: 'Add Event',
                  enabled: canCreate,
                  onPressed: canCreate
                      ? () {
                          showDialog(
                            context: context,
                            builder: (_) => CreateEventPopupView(),
                          );
                        }
                      : null,
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
    });
  }
}
