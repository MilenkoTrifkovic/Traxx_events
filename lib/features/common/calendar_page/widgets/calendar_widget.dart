import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:traxx_wepapp/features/common/calendar_page/controller/calendar_controller.dart';
import 'package:traxx_wepapp/features/common/calendar_page/widgets/calendar_header.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';

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
    final rowHeight = 56.0;
    final dowHeight = 34.0;
    final weeks = calendarFormat == CalendarFormat.month
        ? 6
        : (calendarFormat == CalendarFormat.twoWeeks ? 2 : 1);
    final calendarHeight = dowHeight + (rowHeight * weeks) + 10;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderInput),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          CalendarHeader(
            focusedDay: focusedDay,
            calendarFormat: calendarFormat,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
            onTodayPressed: onTodayPressed,
            onFormatToggle: onFormatToggle,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: calendarHeight,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,

              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              calendarFormat: calendarFormat,

              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: calendarController.getEventsForDay,

              onDaySelected: onDaySelected,
              onFormatChanged: onFormatChanged,
              onPageChanged: onPageChanged,

              headerVisible: false,
              availableGestures: AvailableGestures.horizontalSwipe,

              daysOfWeekHeight: dowHeight,
              rowHeight: rowHeight,

              // ✅ We render markers ourselves inside the tile
              calendarStyle: CalendarStyle(
                markersMaxCount: 0,
                outsideDaysVisible: true,
              ),

              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) => const [
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

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focused) => _dayTile(
                    context, day, focused,
                    isSelected: false, isToday: false, isOutside: false),
                todayBuilder: (context, day, focused) => _dayTile(
                    context, day, focused,
                    isSelected: false, isToday: true, isOutside: false),
                selectedBuilder: (context, day, focused) => _dayTile(
                    context, day, focused,
                    isSelected: true, isToday: false, isOutside: false),
                outsideBuilder: (context, day, focused) => _dayTile(
                    context, day, focused,
                    isSelected: false, isToday: false, isOutside: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTile(BuildContext context, DateTime day, DateTime focusedDay,
      {required bool isSelected,
      required bool isToday,
      required bool isOutside}) {
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    final eventsCount = calendarController.getEventsForDay(day).length;

    final textColor = isOutside
        ? AppColors.onSurface(context).withOpacity(0.35)
        : isWeekend
            ? AppColors.error(context)
            : AppColors.onSurface(context);

    final underlineColor = AppColors.primaryAccent;
    final dotColor = AppColors.primaryAccent;

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Day number
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight:
                    isSelected ? AppFontWeight.bold : AppFontWeight.semiBold,
                color: textColor,
              ),
            ),

            // ✅ Underline for selected date (no circle)
            if (isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: underlineColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

            // ✅ Dots for event dates (bottom)
            if (eventsCount > 0)
              Positioned(
                bottom: isSelected ? 10 : 4, // keep dots above underline
                child: _eventDots(
                  context,
                  count: eventsCount,
                  color: dotColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eventDots(BuildContext context,
      {required int count, required Color color}) {
    final dotCount = math.min(3, count);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < dotCount; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        if (count > 3)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+${count - 3}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: AppFontWeight.semiBold,
                color: AppColors.onSurface(context).withOpacity(0.75),
              ),
            ),
          ),
      ],
    );
  }
}
