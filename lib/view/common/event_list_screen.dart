import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/view/common/widgets/event_filter_section.dart';
import 'package:traxx_wepapp/view/common/widgets/event_list_header_old.dart';
import 'package:traxx_wepapp/view/common/widgets/list_of_events.dart';

/// A screen that displays a list of events for the host user.
///
/// This screen includes:
/// - A search field for filtering events
/// - A sort button for organizing events
/// - A scrollable list of event cards
/// - The behavior of the list items depends on the logged in user type (host/guest).
class EventListScreen extends StatelessWidget {
  EventListScreen({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Event list container
          Obx(() => Container(
              decoration: BoxDecoration(
                color: eventListController.events.isNotEmpty
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Column(
                  children: [
                    // Show header and filters if there are any events in the system
                    if (eventListController.events.isNotEmpty) ...[
                      EventFilterSection(),
                      AppSpacing.verticalXs(context),
                    ],

                    const EventsDataTable(),
                  ],
                ),
              ))),
        ],
      ),
    );
  }
}

class CopyEventDialog extends StatefulWidget {
  final Event source;
  const CopyEventDialog({super.key, required this.source});

  @override
  State<CopyEventDialog> createState() => _CopyEventDialogState();
}

class _CopyEventDialogState extends State<CopyEventDialog> {
  late final TextEditingController _nameCtrl;

  bool _copyDemographics = true;
  bool _copyMenu = true;
  bool _copyVenue = true;
  bool _copyCover = true;

  bool get _selectAll =>
      _copyDemographics && _copyMenu && _copyVenue && _copyCover;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: '${widget.source.name} (Copy)');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _setAll(bool v) {
    setState(() {
      _copyDemographics = v;
      _copyMenu = v;
      _copyVenue = v;
      _copyCover = v;
    });
  }

  Widget _optionTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
    IconData icon = Icons.check_circle_outline,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      title: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Copy Event'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New event name',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter new event name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Select all
              CheckboxListTile(
                value: _selectAll,
                onChanged: (v) => _setAll(v == true),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Select all sections',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(height: 24),

              _optionTile(
                value: _copyDemographics,
                onChanged: (v) => setState(() => _copyDemographics = v == true),
                title: 'Demographic question set',
                subtitle:
                    'Copies the selected demographic question set for this event.',
                icon: Icons.quiz_outlined,
              ),
              _optionTile(
                value: _copyMenu,
                onChanged: (v) => setState(() => _copyMenu = v == true),
                title: 'Menu & dishes',
                subtitle:
                    'Copies the selected menu and selected dish/item IDs for this event.',
                icon: Icons.restaurant_menu_outlined,
              ),
              _optionTile(
                value: _copyVenue,
                onChanged: (v) => setState(() => _copyVenue = v == true),
                title: 'Venue (photos & location)',
                subtitle:
                    'Copies the venue selection so the new event uses the same venue details.',
                icon: Icons.place_outlined,
              ),
              _optionTile(
                value: _copyCover,
                onChanged: (v) => setState(() => _copyCover = v == true),
                title: 'Cover image',
                subtitle: 'Copies the cover image of the event.',
                icon: Icons.image_outlined,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(
              context,
              CopyEventOptions(
                newName: name,
                copyDemographics: _copyDemographics,
                copyMenuAndDishes: _copyMenu,
                copyVenue: _copyVenue,
                copyCoverImage: _copyCover,
              ),
            );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class EventsDataTable extends StatefulWidget {
  const EventsDataTable({super.key});

  @override
  State<EventsDataTable> createState() => _EventsDataTableState();
}

class _EventsDataTableState extends State<EventsDataTable> {
  int _page = 0;
  static const int _pageSize = 10;

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _fmtCreated(DateTime? d) {
    if (d == null) return '—';
    return _fmtDate(d);
  }

  String _fmtTimeOfDay(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _goToEventDetails(BuildContext context, Event e) {
    final id = (e.eventId ?? '').trim();
    if (id.isEmpty) return;

    // Works with a path like "/event-details/:eventId"
    final placeholder = AppRoute.eventDetails.placeholder; // e.g. "eventId"
    final path = AppRoute.eventDetails.path.replaceFirst(':$placeholder', id);

    context.go(path); // requires: import 'package:go_router/go_router.dart';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EventListController>();

    return Obx(() {
      final allRows = controller.filteredEvents.isNotEmpty
          ? controller.filteredEvents
          : controller.events;

      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (allRows.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No events found.')),
        );
      }

      final total = allRows.length;
      final totalPages = (total / _pageSize).ceil();

      // clamp page if list size changed due to filters
      if (_page >= totalPages) _page = totalPages - 1;
      if (_page < 0) _page = 0;

      final start = _page * _pageSize;
      final end = (start + _pageSize) > total ? total : (start + _pageSize);
      final pageRows = allRows.sublist(start, end);

      const headerBg = Color(0xFFF3F4F6); // light gray header background
      const headerText = Color(0xFF111827); // near-black text
      const borderColor = Color(0xFFE5E7EB); // subtle border

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1100),
                  child: DataTable(
                    showCheckboxColumn: false,
                    // ✅ borders/grid lines
                    border: TableBorder(
                      horizontalInside: const BorderSide(color: borderColor),
                      top: const BorderSide(color: borderColor),
                      bottom: const BorderSide(color: borderColor),
                      left: const BorderSide(color: borderColor),
                      right: const BorderSide(color: borderColor),
                      verticalInside: BorderSide.none,
                    ),

                    // ✅ header styling
                    headingRowColor: WidgetStateProperty.all<Color>(headerBg),
                    headingTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: headerText,
                    ),

                    dataTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),

                    headingRowHeight: 52,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 74,

                    columns: const [
                      DataColumn(
                          label: SizedBox(width: 280, child: Text('Event'))),
                      DataColumn(
                          label: SizedBox(width: 180, child: Text('Type'))),
                      DataColumn(
                          label:
                              SizedBox(width: 120, child: Text('Event Date'))),
                      DataColumn(
                          label: SizedBox(
                              width: 120, child: Text('Created Date'))),
                      DataColumn(
                          label: SizedBox(width: 160, child: Text('Time'))),
                      DataColumn(
                          label: SizedBox(width: 100, child: Text('Status'))),
                      DataColumn(
                          label: SizedBox(width: 80, child: Text('Actions'))),
                    ],
                    rows: pageRows.map((e) {
                      final cover = (e.coverImageDownloadUrl ?? '').trim();

                      return DataRow(
                        onSelectChanged: (_) {
                          controller.selectedEvent.value = e; // ✅ set selected
                          _goToEventDetails(context, e);
                        },
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 280,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      color: const Color(0xFFF3F4F6),
                                      child: cover.isEmpty
                                          ? const Icon(Icons.event, size: 20)
                                          : Image.network(
                                              cover,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons
                                                      .broken_image_outlined),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          DataCell(SizedBox(
                            width: 180,
                            child: Text(
                                e.eventType.isNotEmpty ? e.eventType : '—'),
                          )),

                          DataCell(SizedBox(
                            width: 120,
                            child: Text(_fmtDate(e.date)),
                          )),

                          // ✅ NEW: Created Date
                          DataCell(SizedBox(
                            width: 120,
                            child: Text(_fmtCreated(e.createdAt)),
                          )),

                          DataCell(SizedBox(
                            width: 160,
                            child: Text(
                                '${_fmtTimeOfDay(e.startTime)} - ${_fmtTimeOfDay(e.endTime)}'),
                          )),

                          DataCell(SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: e.status == EventStatus.published
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF9CA3AF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.status.name)),
                              ],
                            ),
                          )),

                          DataCell(
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) async {
                                    if (value == 'view') {
                                      controller.selectedEvent.value = e; // ✅
                                      _goToEventDetails(context, e);
                                      return;
                                    }

                                    if (value == 'edit') {
                                      controller.selectedEvent.value = e; // ✅
                                      _goToEventDetails(context, e);
                                      return;
                                    }

                                    if (value == 'copy') {
                                      final opts =
                                          await showDialog<CopyEventOptions?>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) =>
                                            CopyEventDialog(source: e),
                                      );

                                      if (opts == null) return;

                                      await controller.copyEventById(e.eventId!,
                                          options: opts);
                                      return;
                                    }

                                    if (value == 'delete') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: const Text('Delete Event?'),
                                          content: Text(
                                              'Are you sure you want to delete "${e.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogCtx)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogCtx)
                                                      .pop(true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (ok == true) {
                                        await controller
                                            .deleteEventById(e.eventId!);
                                        // ✅ NO fetchEvents here
                                        // ✅ DataTable will refresh automatically because lists updated
                                      }
                                      return;
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                        value: 'view', child: Text('View')),
                                    PopupMenuItem(
                                        value: 'copy', child: Text('Copy')),
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Rows ${start + 1}–$end of $total',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 14),
              IconButton(
                tooltip: 'Previous',
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_page + 1} / $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: (_page + 1) < totalPages
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class CopyEventOptions {
  final String newName;
  final bool copyDemographics;
  final bool copyMenuAndDishes;
  final bool copyVenue;
  final bool copyCoverImage;

  const CopyEventOptions({
    required this.newName,
    required this.copyDemographics,
    required this.copyMenuAndDishes,
    required this.copyVenue,
    required this.copyCoverImage,
  });

  bool get isAllSelected =>
      copyDemographics && copyMenuAndDishes && copyVenue && copyCoverImage;
}
