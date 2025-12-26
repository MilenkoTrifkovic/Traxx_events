import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';

const Color gfBackground = Color(0xFFF4F0FB);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color kGfPurple = Color(0xFF673AB7);

class ThankYouPage extends StatefulWidget {
  final String invitationId;
  const ThankYouPage({super.key, required this.invitationId});

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> {
  @override
  void dispose() {
    // Clean up the controller when guest flow is complete
    Get.delete<RsvpResponseController>(tag: widget.invitationId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Prevent in-app back navigation
    // Return content directly - ShellRoute provides GuestPageWrapper
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: kBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 54, color: kGfPurple),
                    const SizedBox(height: 14),
                    Text(
                      'Thank you!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your responses have been submitted successfully.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kTextBody,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You can now close this tab.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
