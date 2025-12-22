import 'package:get/get.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';

/// Controller for managing event list filters
/// Handles search text, date range, event type, and sort preferences
class EventFilterController extends GetxController {
  // Filter values
  final RxString searchText = ''.obs;
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();
  final RxnString selectedEventType = RxnString();
  final Rxn<SortType> selectedSortType = Rxn<SortType>();

  // UI State
  final RxBool isExpanded = true.obs;

  /// Updates the search text filter
  void updateSearchText(String value) {
    searchText.value = value;
  }

  /// Updates the start date filter
  void updateStartDate(DateTime? date) {
    startDate.value = date;
  }

  /// Updates the end date filter
  void updateEndDate(DateTime? date) {
    endDate.value = date;
  }

  /// Updates the event type filter
  void updateEventType(String? type) {
    selectedEventType.value = type;
  }

  /// Updates the sort type
  void updateSortType(SortType? sortType) {
    selectedSortType.value = sortType;
  }

  /// Toggles the expanded state of the filter section
  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  /// Clears all filters
  void clearAllFilters() {
    searchText.value = '';
    startDate.value = null;
    endDate.value = null;
    selectedEventType.value = null;
    selectedSortType.value = null;
  }

  /// Checks if any filters are active
  bool get hasActiveFilters {
    return searchText.value.isNotEmpty ||
        startDate.value != null ||
        endDate.value != null ||
        selectedEventType.value != null;
  }

  /// Gets the count of active filters
  int get activeFilterCount {
    int count = 0;
    if (searchText.value.isNotEmpty) count++;
    if (startDate.value != null || endDate.value != null) count++;
    if (selectedEventType.value != null) count++;
    return count;
  }
}
