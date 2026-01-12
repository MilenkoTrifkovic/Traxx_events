import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Error state widget shown when invitation fails to load
class RsvpErrorWidget extends StatelessWidget {
  final bool isPhone;
  final String errorMessage;
  final VoidCallback onRetry;

  const RsvpErrorWidget({
    super.key,
    required this.isPhone,
    required this.errorMessage,
    required this.onRetry,
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
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: isPhone ? 40 : 48,
            color: Colors.red.shade700,
          ),
        ),
        SizedBox(height: isPhone ? 24 : 32),
        Text(
          'Oops! Something went wrong',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isPhone ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: isPhone ? 12 : 16),
        Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isPhone ? 14 : 15,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        SizedBox(height: isPhone ? 24 : 32),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isPhone ? 24 : 32,
              vertical: isPhone ? 14 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Try Again',
            style: GoogleFonts.poppins(
              fontSize: isPhone ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
