import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';

/// A search input field widget that provides real-time event filtering functionality.
///
/// This widget creates a styled text field that:
/// - Filters events as the user types
/// - Uses the HostController to manage event filtering
/// - Provides immediate visual feedback
class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  // late AuthController authController;
  late EventListController controller;
  @override
  void initState() {
    controller = Get.find<EventListController>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      // onChanged: (value) => controller.filterEvents(value),
      onChanged: (value) {
        controller.filterEvents(value);
        print('Filtered events: ${controller.filteredEvents.length}');
      },
      decoration: InputDecoration(
        hintText: 'Search...',
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8.0), //Define reusable border radius
        ),
      ),
    );
  }
}
