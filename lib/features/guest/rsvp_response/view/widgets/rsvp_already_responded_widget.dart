import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Widget shown when user has already submitted their RSVP response
class RsvpAlreadyRespondedWidget extends StatelessWidget {
  final bool isPhone;
  final bool isAttending;
  final DateTime? rsvpSubmittedAt;
  final String? declineReason;

  const RsvpAlreadyRespondedWidget({
    super.key,
    required this.isPhone,
    required this.isAttending,
    this.rsvpSubmittedAt,
    this.declineReason,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(),
        SizedBox(height: isPhone ? 32 : 48),
        _buildMessageCard(),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: isPhone ? 80 : 100,
      height: isPhone ? 80 : 100,
      decoration: BoxDecoration(
        color: isAttending ? Colors.green.shade50 : Colors.orange.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAttending ? Colors.green.shade200 : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Icon(
        isAttending ? Icons.check_circle_outline : Icons.event_busy_outlined,
        size: isPhone ? 40 : 48,
        color: isAttending ? Colors.green.shade700 : Colors.orange.shade700,
      ),
    );
  }

  Widget _buildMessageCard() {
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
            'Thank you for responding!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isPhone ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
          SizedBox(height: isPhone ? 16 : 20),
          Text(
            isAttending
                ? 'You\'ve confirmed your attendance. We look forward to seeing you at the event!'
                : 'You\'ve indicated that you won\'t be able to attend. We\'ll miss you!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isPhone ? 14 : 15,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          if (rsvpSubmittedAt != null) _buildResponseDate(),
          if (!isAttending && declineReason != null) _buildDeclineReason(),
        ],
      ),
    );
  }

  Widget _buildResponseDate() {
    return Padding(
      padding: EdgeInsets.only(top: isPhone ? 16 : 20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Responded on ${_formatDate(rsvpSubmittedAt!)}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDeclineReason() {
    return Padding(
      padding: EdgeInsets.only(top: isPhone ? 16 : 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your note:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              declineReason!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange.shade900,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
