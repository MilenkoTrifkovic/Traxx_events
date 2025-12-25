import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Header widget with event icon and name
class RsvpHeaderWidget extends StatelessWidget {
  final bool isPhone;
  final String? eventName;

  const RsvpHeaderWidget({
    super.key,
    required this.isPhone,
    this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon
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

        SizedBox(height: isPhone ? 20 : 24),

        // Event Name (if provided)
        if (eventName != null) ...[
          Text(
            eventName!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isPhone ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Subtitle
        Text(
          'You\'re invited!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isPhone ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Main question card widget
class RsvpQuestionCard extends StatelessWidget {
  final bool isPhone;

  const RsvpQuestionCard({
    super.key,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Will you be attending?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isPhone ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please let us know if you can make it',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isPhone ? 14 : 15,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom button widget for RSVP actions
class RsvpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final bool isPhone;

  const RsvpButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isLoading,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.primary : Colors.white;
    final textColor = isPrimary ? Colors.white : AppColors.primary;
    final borderColor = isPrimary ? AppColors.primary : AppColors.borderSubtle;

    return SizedBox(
      width: double.infinity,
      height: isPhone ? 56 : 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: isPrimary ? 2 : 0,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor,
              width: isPrimary ? 0 : 1.5,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 20 : 24,
            vertical: isPhone ? 14 : 16,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isPhone ? 22 : 24,
                    color: textColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: isPhone ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Error message banner widget
class RsvpErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const RsvpErrorMessage({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.red.shade700),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Footer note widget
class RsvpFooterNote extends StatelessWidget {
  final bool isPhone;

  const RsvpFooterNote({
    super.key,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Your response helps us plan better. Thank you!',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: isPhone ? 12 : 13,
        color: AppColors.textMuted,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
