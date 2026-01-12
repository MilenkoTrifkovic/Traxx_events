import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/compaignons_info_page.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/guest_count_page.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/rsvp_response_page.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/admin/event_details/demographicResponsePage_refactored.dart';
import 'package:traxx_wepapp/view/admin/event_details/menuResponsePage_refactored.dart';

/// Widget that displays preview content for a selected step
class PreviewStepContent extends StatelessWidget {
  final String stepId;
  final Event event;

  const PreviewStepContent({
    super.key,
    required this.stepId,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    switch (stepId) {
      case 'rsvp':
        return RsvpResponsePage(
          invitationId: 'preview',
          readOnly: true,
          event: event,
        );
      case 'guest_count':
        return GuestCountPage(
          invitationId: 'preview',
          readOnly: true,
          event: event,
        );
      case 'companions_info':
        return CompaignonsInfoPage(
          invitationId: 'preview',
          readOnly: true,
          event: event,
        );
      case 'demographics':
        if (event.selectedDemographicQuestionSetId == null ||
            event.selectedDemographicQuestionSetId!.isEmpty) {
          return _buildPlaceholder('No demographic question set configured');
        }
        return DemographicResponsePage.preview(
          questionSetId: event.selectedDemographicQuestionSetId!,
        );
      case 'menu':
        if (event.selectedMenuItemIds == null || event.selectedMenuItemIds!.isEmpty) {
          return _buildPlaceholder('No menu items configured');
        }
        return GuestMenuSelectionPage.preview(
          selectedMenuItemIds: event.selectedMenuItemIds!,
        );
      default:
        return _buildPlaceholder('Step preview not available');
    }
  }

  Widget _buildPlaceholder(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderInput),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

