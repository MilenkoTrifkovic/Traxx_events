import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:traxx_wepapp/features/common/calendar_page/controller/calendar_controller.dart';
import 'package:traxx_wepapp/features/common/calendar_page/widgets/calendar_header.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';

/// Calendar widget displaying a monthly/weekly calendar with navigation
///
/// Features:
/// - Custom header with format toggle and today button
/// - Month navigation with arrow buttons
/// - Event markers on dates with events
/// - Responsive calendar format (month/2 weeks/week)
class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final CalendarController calendarController;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(CalendarFormat format) onFormatChanged;
  final Function(DateTime focusedDay) onPageChanged;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayPressed;
  final VoidCallback onFormatToggle;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.calendarController,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayPressed,
    required this.onFormatToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderInput,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
      child: Column(
        children: [
          // Custom header with navigation and format buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CalendarHeader(
              focusedDay: focusedDay,
              calendarFormat: calendarFormat,
              onPreviousMonth: onPreviousMonth,
              onNextMonth: onNextMonth,
              onTodayPressed: onTodayPressed,
              onFormatToggle: onFormatToggle,
            ),
          ),

          const SizedBox(height: 12.0),

          // Calendar
          SizedBox(
            height: calendarFormat == CalendarFormat.month
                ? 400.0
                : (calendarFormat == CalendarFormat.twoWeeks ? 300.0 : 200.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              calendarFormat: calendarFormat,

              // Start week from Monday
              startingDayOfWeek: StartingDayOfWeek.monday,

              // Event loader
              eventLoader: calendarController.getEventsForDay,

              // Callbacks
              onDaySelected: onDaySelected,
              onFormatChanged: onFormatChanged,
              onPageChanged: onPageChanged,

              // Hide default header since we have custom one
              headerVisible: false,

              // Days of week styling (Mon, Tue, Wed, etc.) - Bold
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) => [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun'
                ][date.weekday - 1],
                weekdayStyle: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.onSurface(context),
                  fontSize: 13.0,
                ),
                weekendStyle: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.error(context),
                  fontSize: 13.0,
                ),
              ),

              // Reduce space between day headers and calendar grid
              daysOfWeekHeight: 32.0,

              // Styling
              calendarStyle: CalendarStyle(
                // Day numbers (1, 2, 3, etc.) - Semi-bold
                defaultTextStyle: TextStyle(
                  fontWeight: AppFontWeight.semiBold,
                ),
                weekendTextStyle: TextStyle(
                  fontWeight: AppFontWeight.semiBold,
                  color: AppColors.error(context),
                ),
                todayTextStyle: TextStyle(
                  fontWeight: AppFontWeight.semiBold,
                ),
                selectedTextStyle: TextStyle(
                  fontWeight: AppFontWeight.semiBold,
                ),

                todayDecoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
