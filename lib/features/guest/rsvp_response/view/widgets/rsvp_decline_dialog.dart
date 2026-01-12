import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Dialog shown when user selects "No, I can't make it"
/// Allows user to optionally provide a reason for declining
class RsvpDeclineDialog {
  /// Shows the decline dialog and returns the optional decline reason
  static Future<String?> show({
    required BuildContext context,
    required Function(String?) onConfirm,
  }) async {
    final isPhone = ScreenSize.isPhone(context);
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'We\'ll miss you!',
          style: GoogleFonts.poppins(
            fontSize: isPhone ? 18 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to share why you can\'t attend? (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'e.g., Schedule conflict, Can\'t make it...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final reason = reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim();
              onConfirm(reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
