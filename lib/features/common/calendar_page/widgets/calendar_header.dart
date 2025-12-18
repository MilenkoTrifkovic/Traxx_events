import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

/// Calendar header widget with responsive layouts for different screen sizes
///
/// Displays month navigation, format toggle, and today button
/// - Desktop/Tablet: Single row with three sections
/// - Phone: Two rows for better mobile UX
class CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayPressed;
  final VoidCallback onFormatToggle;

  const CalendarHeader({
    super.key,
    required this.focusedDay,
    required this.calendarFormat,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayPressed,
    required this.onFormatToggle,
  });

  /// Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Desktop/Tablet header layout - Single row with three sections
  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        // Left section: Format button
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppPrimaryButton(
              text: calendarFormat == CalendarFormat.month
                  ? 'Month'
                  : (calendarFormat == CalendarFormat.twoWeeks
                      ? '2 weeks'
                      : 'Week'),
              onPressed: onFormatToggle,
              height: 36.0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Center section: Month navigation
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 24.0, color: AppColors.primaryAccent),
              onPressed: onPreviousMonth,
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(),
              tooltip: 'Previous month',
            ),
            const SizedBox(width: 8.0),
            AppText.styledBodyLarge(
              context,
              '${_getMonthName(focusedDay.month)} ${focusedDay.year}',
              weight: AppFontWeight.semiBold,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: Icon(Icons.chevron_right,
                  size: 24.0, color: AppColors.primaryAccent),
              onPressed: onNextMonth,
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(),
              tooltip: 'Next month',
            ),
          ],
        ),

        // Right section: Today button
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: AppPrimaryButton(
              text: 'Today',
              icon: Icons.today,
              onPressed: onTodayPressed,
              height: 36.0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Phone header layout - Two rows for better mobile UX
  Widget _buildPhoneHeader(BuildContext context) {
    return Column(
      children: [
        // First row: Format and Today buttons
        Row(
          children: [
            Expanded(
              child: AppPrimaryButton(
                text: calendarFormat == CalendarFormat.month
                    ? 'Month'
                    : (calendarFormat == CalendarFormat.twoWeeks
                        ? '2 weeks'
                        : 'Week'),
                onPressed: onFormatToggle,
                height: 36.0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: AppPrimaryButton(
                text: 'Today',
                icon: Icons.today,
                onPressed: onTodayPressed,
                height: 36.0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12.0),

        // Second row: Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 24.0, color: AppColors.primaryAccent),
              onPressed: onPreviousMonth,
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(),
              tooltip: 'Previous month',
            ),
            const SizedBox(width: 12.0),
            AppText.styledBodyLarge(
              context,
              '${_getMonthName(focusedDay.month)} ${focusedDay.year}',
              weight: AppFontWeight.semiBold,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(width: 12.0),
            IconButton(
              icon: Icon(Icons.chevron_right,
                  size: 24.0, color: AppColors.primaryAccent),
              onPressed: onNextMonth,
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(),
              tooltip: 'Next month',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return isPhone ? _buildPhoneHeader(context) : _buildDesktopHeader(context);
  }
}
