import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';

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

  String get _formatLabel {
    switch (calendarFormat) {
      case CalendarFormat.month:
        return "Month";
      case CalendarFormat.twoWeeks:
        return "2 Weeks";
      case CalendarFormat.week:
        return "Week";
      default:
        return "Month";
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat.yMMMM().format(focusedDay);

    final formatChip = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onFormatToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_agenda_rounded,
                size: 18, color: AppColors.primaryAccent),
            const SizedBox(width: 8),
            Text(
              _formatLabel,
              style: TextStyle(
                fontWeight: AppFontWeight.semiBold,
                color: AppColors.onSurface(context),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.onSurface(context).withOpacity(.7)),
          ],
        ),
      ),
    );

    final monthNav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconCircle(
          context,
          icon: Icons.chevron_left_rounded,
          onTap: onPreviousMonth,
        ),
        const SizedBox(width: 10),
        Text(
          monthTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: AppFontWeight.bold,
            color: AppColors.onSurface(context),
          ),
        ),
        const SizedBox(width: 10),
        _iconCircle(
          context,
          icon: Icons.chevron_right_rounded,
          onTap: onNextMonth,
        ),
      ],
    );

    final todayBtn = OutlinedButton.icon(
      onPressed: onTodayPressed,
      icon: const Icon(Icons.calendar_today_rounded, size: 16),
      label: const Text("Today"),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        side: BorderSide(color: AppColors.primaryAccent.withOpacity(0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // ✅ Wrap handles narrow widths without LayoutBuilder/Spacer issues
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        formatChip,
        monthNav,
        todayBtn,
      ],
    );
  }

  Widget _iconCircle(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.onSurface(context).withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderInput.withOpacity(0.55)),
        ),
        child: Icon(icon, color: AppColors.onSurface(context), size: 22),
      ),
    );
  }
}
