import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final w = MediaQuery.sizeOf(context).width;
    final bool tight = w < 600;

    final outerRadius = BorderRadius.circular(16);
    final innerRadius = BorderRadius.circular(14);

    return DefaultTextStyle(
      style: GoogleFonts.poppins(),
      child: Obx(() {
        final expanded = filterController.isExpanded.value;
        final hasActive = filterController.hasActiveFilters;
        final activeCount = filterController.activeFilterCount;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: outerRadius,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: outerRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Header (fancy)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: filterController.toggleExpanded,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tight ? 14 : 18,
                        vertical: tight ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        // subtle "premium" tint
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF8FAFC),
                            Colors.white,
                          ],
                        ),
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFEEF2FF),
                              border:
                                  Border.all(color: const Color(0xFFE0E7FF)),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: Color(0xFF3730A3),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Filter Events',
                                  style: GoogleFonts.poppins(
                                    fontSize: tight ? 14 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                if (hasActive) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF7C3AED)
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '$activeCount active',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Right-side actions
                          if (hasActive)
                            TextButton(
                              onPressed: () {
                                filterController.clearAllFilters();
                                searchController.clear();
                                eventListController.filterEvents('');
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
                                ),
                                backgroundColor: const Color(0xFFF9FAFB),
                              ),
                              child: Text(
                                'Clear All',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),

                          const SizedBox(width: 8),

                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFF3F4F6),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ✅ Body (collapsible)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding: EdgeInsets.all(tight ? 14 : 18),
                    color: Colors.white,
                    child: Container(
                      padding: EdgeInsets.all(tight ? 12 : 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: innerRadius,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
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
                  ),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  firstCurve: Curves.easeOut,
                  secondCurve: Curves.easeOut,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _applyFilters() {
    eventListController.applyFilters(
      searchText: filterController.searchText.value,
      startDate: filterController.startDate.value,
      endDate: filterController.endDate.value,
      eventType: filterController.selectedEventType.value,
    );
  }
}
