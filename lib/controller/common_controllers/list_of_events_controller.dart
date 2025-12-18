import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';

/// Controller for managing pagination and display logic for the list of events
class ListOfEventsController extends GetxController {
  static const int eventsPerPage = 7;
  
  final RxInt _currentPage = 0.obs;
  
  int get currentPage => _currentPage.value;
  
  /// Get paginated events from the filtered events list
  List<Event> getPaginatedEvents(List<Event> filteredEvents) {
    final totalEvents = filteredEvents.length;
    final startIndex = _currentPage.value * eventsPerPage;
    final endIndex = (startIndex + eventsPerPage).clamp(0, totalEvents);
    
    return filteredEvents.sublist(startIndex, endIndex);
  }
  
  /// Calculate total number of pages
  int getTotalPages(List<Event> filteredEvents) {
    if (filteredEvents.isEmpty) return 0;
    return (filteredEvents.length / eventsPerPage).ceil();
  }
  
  /// Check if there is a previous page
  bool get hasPreviousPage => _currentPage.value > 0;
  
  /// Check if there is a next page
  bool hasNextPage(List<Event> filteredEvents) {
    final totalPages = getTotalPages(filteredEvents);
    return _currentPage.value < totalPages - 1;
  }
  
  /// Navigate to the previous page
  void previousPage() {
    if (hasPreviousPage) {
      _currentPage.value--;
    }
  }
  
  /// Navigate to the next page
  void nextPage(List<Event> filteredEvents) {
    if (hasNextPage(filteredEvents)) {
      _currentPage.value++;
    }
  }
  
  /// Reset to first page (useful when filters change)
  void resetPage() {
    _currentPage.value = 0;
  }
  
  /// Get display text for pagination
  String getPaginationText(List<Event> filteredEvents) {
    final totalPages = getTotalPages(filteredEvents);
    return 'Page ${_currentPage.value + 1} of $totalPages';
  }
}
