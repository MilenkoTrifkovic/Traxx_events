import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Loading state widget shown while checking RSVP status
class RsvpLoadingWidget extends StatelessWidget {
  final bool isPhone;

  const RsvpLoadingWidget({
    super.key,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isPhone ? 80 : 100,
          height: isPhone ? 80 : 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.event_outlined,
            size: isPhone ? 40 : 48,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: isPhone ? 32 : 48),
        const CircularProgressIndicator(),
        SizedBox(height: isPhone ? 16 : 24),
        Text(
          'Loading invitation...',
          style: GoogleFonts.poppins(
            fontSize: isPhone ? 14 : 16,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
