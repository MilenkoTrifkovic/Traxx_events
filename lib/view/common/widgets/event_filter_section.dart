import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_filter_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/common/widgets/event_filter_layouts/desktop_filter_layout.dart';
import 'package:traxx_wepapp/view/common/widgets/event_filter_layouts/mobile_filter_layout.dart';
import 'package:traxx_wepapp/view/common/widgets/event_filter_layouts/tablet_filter_layout.dart';

/// Filter section for event list with search, date range, event type, and sort
/// Positioned between EventListHeader and ListOfEvents
class EventFilterSection extends StatefulWidget {
  const EventFilterSection({super.key});

  @override
  State<EventFilterSection> createState() => _EventFilterSectionState();
}

class _EventFilterSectionState extends State<EventFilterSection> {
  final EventFilterController filterController =
      Get.put(EventFilterController());
  final EventListController eventListController =
      Get.find<EventListController>();

  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController =
        TextEditingController(text: filterController.searchText.value);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenSize.isDesktop(context);
    final isTablet = ScreenSize.isTablet(context);

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.borderInput,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and collapse button
            InkWell(
              onTap: () => filterController.toggleExpanded(),
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        AppSpacing.horizontalXxxs(context),
                        AppText.styledBodyLarge(
                          context,
                          'Filter Events',
                        ),
                        if (filterController.hasActiveFilters) ...[
                          AppSpacing.horizontalXxxs(context),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AppText.styledMetaSmall(
                              context,
                              '${filterController.activeFilterCount}',
                              color: AppColors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (filterController.hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              filterController.clearAllFilters();
                              searchController.clear();
                              eventListController.filterEvents('');
                            },
                            child: AppText.styledBodyMedium(
                              context,
                              'Clear All',
                              color: AppColors.primaryAccent,
                              weight: FontWeight.w600,
                            ),
                          ),
                        Icon(
                          filterController.isExpanded.value
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter content (collapsible)
            if (filterController.isExpanded.value) ...[
              Divider(
                height: 1,
                color: AppColors.borderInput,
              ),
              Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: isDesktop
                    ? DesktopFilterLayout(
                        filterController: filterController,
                        eventListController: eventListController,
                        searchController: searchController,
                        onFiltersChanged: _applyFilters,
                      )
                    : isTablet
                        ? TabletFilterLayout(
                            filterController: filterController,
                            eventListController: eventListController,
                            searchController: searchController,
                            onFiltersChanged: _applyFilters,
                          )
                        : MobileFilterLayout(
                            filterController: filterController,
                            eventListController: eventListController,
                            searchController: searchController,
                            onFiltersChanged: _applyFilters,
                          ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Applies all active filters to the event list
  void _applyFilters() {
    eventListController.applyFilters(
      searchText: filterController.searchText.value,
      startDate: filterController.startDate.value,
      endDate: filterController.endDate.value,
      eventType: filterController.selectedEventType.value,
    );
  }
}
