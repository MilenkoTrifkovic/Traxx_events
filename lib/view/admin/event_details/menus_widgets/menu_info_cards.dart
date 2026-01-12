import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_constants.dart';

/// A card widget displayed when menu has already been submitted.
class MenuAlreadySubmittedCard extends StatelessWidget {
  /// Callback when "Continue" is tapped.
  final VoidCallback onContinue;

  const MenuAlreadySubmittedCard({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Already submitted',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click Continue to proceed',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: kTextBody,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGfPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card widget displayed when there are no menu items to show.
class MenuEmptyCard extends StatelessWidget {
  /// The message to display.
  final String message;

  const MenuEmptyCard({
    super.key,
    this.message = 'No menu items available for this event.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A card widget displayed when there's an error loading menu.
class MenuErrorCard extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when retry is tapped.
  final VoidCallback? onRetry;

  const MenuErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading menu',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14, color: kTextBody),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGfPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
