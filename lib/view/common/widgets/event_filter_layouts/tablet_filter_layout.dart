import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_filter_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/date_time_input_type.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';
import 'package:traxx_wepapp/utils/static_data.dart';
import 'package:traxx_wepapp/widgets/app_date_time_input_field.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';

/// Tablet layout: filters in two rows
class TabletFilterLayout extends StatelessWidget {
  final EventFilterController filterController;
  final EventListController eventListController;
  final TextEditingController searchController;
  final VoidCallback onFiltersChanged;

  const TabletFilterLayout({
    super.key,
    required this.filterController,
    required this.eventListController,
    required this.searchController,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row: Search and Sort
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label to match other fields
                  SizedBox(
                    height: 20.0,
                    child: AppText.styledBodyMedium(
                      context,
                      'Search',
                      weight: AppFontWeight.semiBold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  AppSearchInputField(
                    hintText: 'Search events...',
                    controller: searchController,
                    onChanged: (value) {
                      filterController.updateSearchText(value);
                      eventListController.filterEvents(value);
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalXs(context),
            SizedBox(
              width: 180,
              child: AppDropdownMenu<SortType>(
                label: 'Sort By',
                hintText: 'Select sort',
                value: filterController.selectedSortType.value,
                items: [
                  DropdownMenuItem<SortType>(
                    value: SortType.dateNewest,
                    child: AppText.styledBodyMedium(context, 'Date (Newest)'),
                  ),
                  DropdownMenuItem<SortType>(
                    value: SortType.dateOldest,
                    child: AppText.styledBodyMedium(context, 'Date (Oldest)'),
                  ),
                  DropdownMenuItem<SortType>(
                    value: SortType.nameAZ,
                    child: AppText.styledBodyMedium(context, 'Name (A-Z)'),
                  ),
                  DropdownMenuItem<SortType>(
                    value: SortType.nameZA,
                    child: AppText.styledBodyMedium(context, 'Name (Z-A)'),
                  ),
                ],
                onChanged: (value) {
                  filterController.updateSortType(value);
                  if (value != null) {
                    eventListController.sortEvents(value);
                  }
                },
              ),
            ),
          ],
        ),
        AppSpacing.verticalXs(context),

        // Second row: Date range and Event Type
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDateTimeInputField(
                label: 'Start Date',
                inputType: DateTimeInputType.dateOnly,
                hintText: 'Select start date',
                selectedDateTime: filterController.startDate.value,
                onChanged: (date) {
                  filterController.updateStartDate(date);
                  onFiltersChanged();
                },
              ),
            ),
            AppSpacing.horizontalXs(context),
            Expanded(
              child: AppDateTimeInputField(
                label: 'End Date',
                inputType: DateTimeInputType.dateOnly,
                hintText: 'Select end date',
                selectedDateTime: filterController.endDate.value,
                firstDate: filterController.startDate.value,
                onChanged: (date) {
                  filterController.updateEndDate(date);
                  onFiltersChanged();
                },
              ),
            ),
            AppSpacing.horizontalXs(context),
            Expanded(
              child: AppDropdownMenu<String>(
                label: 'Event Type',
                hintText: 'All Types',
                value: filterController.selectedEventType.value,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: AppText.styledBodyMedium(context, 'All Types'),
                  ),
                  ...StaticData.eventTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: AppText.styledBodyMedium(context, type),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  filterController.updateEventType(value);
                  onFiltersChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
