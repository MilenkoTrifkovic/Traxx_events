import 'package:flutter/material.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/view/admin/event_details/demographic_widgets/demographic_constants.dart';

class GuestThankYouPage extends StatelessWidget {
  final String invitationId;
  final String token;

  const GuestThankYouPage({
    super.key,
    required this.invitationId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 700;
    final attendingParam = (Uri.base.queryParameters['attending'] ?? '').trim();
    final bool? attending = attendingParam == '1'
        ? true
        : attendingParam == '0'
            ? false
            : null;

    final message = attending == false
        ? 'Your response has been submitted. We’ve recorded that you’re not attending.'
        : 'Your RSVP, demographics, and menu selections have been submitted.';

    return Scaffold(
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: ColoredBox(color: gfBackground),
          ),

          // Soft decorative blobs (optional but nice)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: kGfPurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -90,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: kGfPurple.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 16 : 24),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      isPhone ? 18 : 26,
                      isPhone ? 18 : 26,
                      isPhone ? 18 : 26,
                      isPhone ? 16 : 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: kGfPurple.withOpacity(0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon badge
                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            color: kGfPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: kGfPurple,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'Thank you!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: isPhone ? 26 : 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.88),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.55),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Primary CTA
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(
                              'View Event Details',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGfPurple,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              pushAndRemoveAllRoute(
                                AppRoute.guestResponse,
                                context,
                                queryParams: {
                                  'invitationId': invitationId,
                                  if (token.isNotEmpty) 'token': token,
                                  'view': 'details',
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'You can safely close this tab now.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
