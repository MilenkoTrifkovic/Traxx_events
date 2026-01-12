import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:velocity_x/velocity_x.dart';

/// Header widget with event icon and key event details
class RsvpHeaderWidget extends StatelessWidget {
  final bool isPhone;
  final String? eventName;
  final DateTime? eventDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? eventAddress;
  final String? eventType;

  const RsvpHeaderWidget({
    super.key,
    required this.isPhone,
    this.eventName,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.eventAddress,
    this.eventType,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isPhone 
          ? AppSpacing.lg(context) 
          : AppSpacing.xl(context)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Greeting message
          AppText.styledLabelSmall(
            context,
            'EVENT INVITATION',
            textAlign: TextAlign.center,
            color: AppColors.primaryAccent,
            weight: AppFontWeight.semiBold,
          ),
          
          SizedBox(height: AppSpacing.sm(context)),
          
          // Event Icon with type badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isPhone ? 72 : 80,
                height: isPhone ? 72 : 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryAccent.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.celebration_outlined,
                  size: isPhone ? 36 : 40,
                  color: AppColors.primaryAccent,
                ),
              ),
              // Event type badge (if available)
              if (eventType != null && eventType!.isNotEmpty)
                Positioned(
                  right: -8,
                  bottom: -4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxs(context),
                      vertical: AppSpacing.xxxxs(context),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      eventType!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: AppFontWeight.semiBold,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: isPhone 
              ? AppSpacing.md(context) 
              : AppSpacing.lg(context)),

          // Event Name
          if (eventName != null && eventName!.isNotEmpty) ...[
            AppText.styledHeadingMedium(
              context,
              eventName!.capitalized,
              textAlign: TextAlign.center,
              color: AppColors.primary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.xxxxs(context)),
          ],

          // "You're invited!" subtitle
          AppText.styledLabelMedium(
            context,
            'You\'re Invited!',
            textAlign: TextAlign.center,
            color: AppColors.primaryAccent,
            weight: AppFontWeight.semiBold,
          ),

          // Event details section (if available)
          if (eventDate != null || startTime != null || eventAddress != null) ...[
            SizedBox(height: isPhone 
                ? AppSpacing.md(context) 
                : AppSpacing.lg(context)),
            
            Container(
              padding: EdgeInsets.all(isPhone 
                  ? AppSpacing.sm(context) 
                  : AppSpacing.md(context)),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Date and Time row
                  if (eventDate != null) ...[
                    _buildInfoRow(
                      context: context,
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(eventDate!),
                      isPhone: isPhone,
                    ),
                    if (startTime != null) 
                      SizedBox(height: AppSpacing.xxxs(context)),
                  ],
                  
                  // Time
                  if (startTime != null)
                    _buildInfoRow(
                      context: context,
                      icon: Icons.access_time_outlined,
                      label: endTime != null
                          ? '${_formatTime(startTime!)} - ${_formatTime(endTime!)}'
                          : _formatTime(startTime!),
                      isPhone: isPhone,
                    ),
                  
                  // Address
                  if (eventAddress != null && eventAddress!.isNotEmpty) ...[
                    if (eventDate != null || startTime != null)
                      SizedBox(height: AppSpacing.xxxs(context)),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.location_on_outlined,
                      label: eventAddress!,
                      isPhone: isPhone,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPhone,
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: isPhone ? 16 : 18,
          color: AppColors.primaryAccent,
        ),
        SizedBox(width: AppSpacing.xxxs(context)),
        Expanded(
          child: AppText.styledBodySmall(
            context,
            label,
            color: AppColors.secondary,
            weight: AppFontWeight.medium,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.all(isPhone 
          ? AppSpacing.xl(context) 
          : AppSpacing.xxxl(context)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Context text
          AppText.styledBodySmall(
            context,
            'Your presence would mean the world to us',
            textAlign: TextAlign.center,
            color: AppColors.textMuted,
            weight: AppFontWeight.regular,
          ),
          
          SizedBox(height: AppSpacing.md(context)),
          
          AppText.styledHeadingMedium(
            context,
            'Will you be attending?',
            textAlign: TextAlign.center,
            color: AppColors.primary,
            weight: AppFontWeight.bold,
          ),
          SizedBox(height: AppSpacing.sm(context)),
          AppText.styledBodyMedium(
            context,
            'Please let us know if you can make it',
            textAlign: TextAlign.center,
            color: AppColors.textMuted,
            weight: AppFontWeight.regular,
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
    final bgColor = isPrimary ? AppColors.primary : AppColors.white;
    final textColor = isPrimary ? AppColors.white : AppColors.primary;
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
          shadowColor: AppColors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor,
              width: isPrimary ? 0 : 1.5,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone 
                ? AppSpacing.lg(context) 
                : AppSpacing.xl(context),
            vertical: 0,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? AppColors.white : AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isPhone ? 22 : 24,
                    color: textColor,
                  ),
                  SizedBox(width: AppSpacing.sm(context)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isPhone ? 15 : 16,
                      fontWeight: AppFontWeight.semiBold,
                      color: textColor,
                      height: 1.0,
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
      padding: EdgeInsets.all(AppSpacing.md(context)),
      decoration: BoxDecoration(
        color: AppColors.inputError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputError.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline, 
            color: AppColors.inputError, 
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm(context)),
          Expanded(
            child: AppText.styledBodySmall(
              context,
              message,
              color: AppColors.inputError,
              weight: AppFontWeight.medium,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close, 
              size: 18, 
              color: AppColors.inputError,
            ),
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
    return Column(
      children: [
        AppText.styledBodySmall(
          context,
          'Your response helps us plan better',
          textAlign: TextAlign.center,
          color: AppColors.textMuted,
          weight: AppFontWeight.medium,
        ),
        SizedBox(height: AppSpacing.xxxxs(context)),
        AppText.styledMetaSmall(
          context,
          'We look forward to celebrating with you!',
          textAlign: TextAlign.center,
          color: AppColors.textMuted,
          weight: AppFontWeight.regular,
          style: FontStyle.italic,
        ),
      ],
    );
  }
}
