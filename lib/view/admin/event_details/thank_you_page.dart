import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_completed_event_details.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_error_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_loading_widget.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';

const Color gfBackground = Color(0xFFF4F0FB);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color kGfPurple = Color(0xFF673AB7);

class ThankYouPage extends StatelessWidget {
  final String invitationId;

  const ThankYouPage({super.key, required this.invitationId});

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    final rsvpCtrl = Get.find<RsvpResponseController>(tag: invitationId);

    if (!Get.isRegistered<GuestLayoutController>(tag: invitationId)) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }
    final guestCtrl = Get.find<GuestLayoutController>(tag: invitationId);

    return Obx(() {
      if (rsvpCtrl.isLoading.value) {
        return RsvpLoadingWidget(isPhone: isPhone);
      }

      if (rsvpCtrl.error.value != null && !rsvpCtrl.hasResponded) {
        return RsvpErrorWidget(
          isPhone: isPhone,
          errorMessage: rsvpCtrl.error.value!,
          onRetry: () => rsvpCtrl.checkExistingResponse(),
        );
      }

      return RsvpCompletedEventDetailsWidget(
        isPhone: isPhone,
        controller: rsvpCtrl,
        guestController: guestCtrl,
      );
    });
  }
}
