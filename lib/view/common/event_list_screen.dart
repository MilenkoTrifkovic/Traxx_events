import 'dart:math' as math;

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

class EventListScreen extends StatelessWidget {
  EventListScreen({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    // ✅ stretch full width in the available content area
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Obx(() {
          final hasEvents = eventListController.events.isNotEmpty;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasEvents ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: AppPadding.all(context, paddingType: Sizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasEvents) ...[
                    EventFilterSection(),
                    AppSpacing.verticalXs(context),
                  ],
                  const EventsDataTable(),
                ],
              ),
            ),
          );
        }),
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
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    // ✅ responsive dialog width
    final dialogW = w < 600 ? w * 0.92 : (w < 1200 ? 520.0 : 560.0);

    return AlertDialog(
      insetPadding:
          EdgeInsets.symmetric(horizontal: w < 600 ? 16 : 40, vertical: 24),
      title: const Text('Copy Event'),
      content: SizedBox(
        width: dialogW,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New event name',
                  style: TextStyle(fontWeight: FontWeight.w700)),
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
              CheckboxListTile(
                value: _selectAll,
                onChanged: (v) => _setAll(v == true),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Select all sections',
                    style: TextStyle(fontWeight: FontWeight.w800)),
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
            child: const Text('Cancel')),
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

  String _fmtCreated(DateTime? d) => d == null ? '—' : _fmtDate(d);

  String _fmtTimeOfDay(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _goToEventDetails(BuildContext context, Event e) {
    final id = (e.eventId ?? '').trim();
    if (id.isEmpty) return;

    final placeholder = AppRoute.eventDetails.placeholder;
    final path = AppRoute.eventDetails.path.replaceFirst(':$placeholder', id);
    context.go(path);
  }

  Future<void> _handleAction(
    BuildContext context, {
    required String value,
    required Event e,
    required EventListController controller,
  }) async {
    if (value == 'view' || value == 'edit') {
      controller.selectedEvent.value = e;
      _goToEventDetails(context, e);
      return;
    }

    if (value == 'copy') {
      final opts = await showDialog<CopyEventOptions?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CopyEventDialog(source: e),
      );
      if (opts == null) return;
      await controller.copyEventById(e.eventId!, options: opts);
      return;
    }

    if (value == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Delete Event?'),
          content: Text('Are you sure you want to delete "${e.name}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Delete')),
          ],
        ),
      );

      if (ok == true) {
        await controller.deleteEventById(e.eventId!);
      }
    }
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
      final totalPages = math.max(1, (total / _pageSize).ceil());
      final page = _page.clamp(0, totalPages - 1);

      if (page != _page) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _page = page);
        });
      }

      final start = page * _pageSize;
      final end = math.min(start + _pageSize, total);
      final pageRows = allRows.sublist(start, end);

      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // ✅ Mobile/tablet: cards. Desktop: table
          final isCompact = w < 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCompact)
                _buildCompactCards(context, controller, pageRows)
              else
                _buildDesktopTable(context, controller, pageRows, constraints),

              const SizedBox(height: 12),

              // ✅ Pagination (Wrap on small screens to avoid overflow)
              (w < 600)
                  ? Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: _paginationChildren(
                          start, end, total, page, totalPages),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _paginationChildren(
                          start, end, total, page, totalPages),
                    ),
            ],
          );
        },
      );
    });
  }

  List<Widget> _paginationChildren(
      int start, int end, int total, int page, int totalPages) {
    return [
      Text('Rows ${start + 1}–$end of $total',
          style: const TextStyle(color: Color(0xFF6B7280))),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Previous',
        onPressed: page > 0 ? () => setState(() => _page--) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Text('${page + 1} / $totalPages',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      IconButton(
        tooltip: 'Next',
        onPressed:
            (page + 1) < totalPages ? () => setState(() => _page++) : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ];
  }

  Widget _buildCompactCards(
    BuildContext context,
    EventListController controller,
    List<Event> rows,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = rows[i];
        final cover = (e.coverImageDownloadUrl ?? '').trim();

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            controller.selectedEvent.value = e;
            _goToEventDetails(context, e);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFF3F4F6),
                    child: cover.isEmpty
                        ? const Icon(Icons.event, size: 22)
                        : Image.network(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.eventType.isNotEmpty ? e.eventType : '—'} • ${_fmtDate(e.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmtTimeOfDay(e.startTime)} - ${_fmtTimeOfDay(e.endTime)}',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
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
                          Expanded(
                            child: Text(
                              e.status.name,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleAction(
                    context,
                    value: value,
                    e: e,
                    controller: controller,
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'view', child: Text('View')),
                    PopupMenuItem(value: 'copy', child: Text('Copy')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    EventListController controller,
    List<Event> pageRows,
    BoxConstraints constraints,
  ) {
    const headerBg = Color(0xFFF3F4F6);
    const headerText = Color(0xFF111827);
    const borderColor = Color(0xFFE5E7EB);

    // ✅ Fill available width (no “small centered table” on big screens)
    final minTableWidth = math.max(1100.0, constraints.maxWidth);

    // ✅ responsive font sizes
    final w = constraints.maxWidth;
    final headingFont = w < 1300 ? 16.0 : 18.0;
    final dataFont = w < 1300 ? 14.0 : 16.0;

    return Container(
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
            constraints: BoxConstraints(minWidth: minTableWidth),
            child: DataTable(
              showCheckboxColumn: false,
              border: TableBorder(
                horizontalInside: const BorderSide(color: borderColor),
                top: const BorderSide(color: borderColor),
                bottom: const BorderSide(color: borderColor),
                left: const BorderSide(color: borderColor),
                right: const BorderSide(color: borderColor),
                verticalInside: BorderSide.none,
              ),
              headingRowColor: WidgetStateProperty.all<Color>(headerBg),
              headingTextStyle: TextStyle(
                fontSize: headingFont,
                fontWeight: FontWeight.w800,
                color: headerText,
              ),
              dataTextStyle: TextStyle(
                fontSize: dataFont,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
              headingRowHeight: 52,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 74,
              columns: const [
                DataColumn(label: Text('Event')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Event Date')),
                DataColumn(label: Text('Created Date')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: pageRows.map((e) {
                final cover = (e.coverImageDownloadUrl ?? '').trim();

                return DataRow(
                  onSelectChanged: (_) {
                    controller.selectedEvent.value = e;
                    _goToEventDetails(context, e);
                  },
                  cells: [
                    DataCell(
                      Row(
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
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image_outlined),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 280,
                            child: Text(
                              e.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: dataFont,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(SizedBox(
                        width: 180,
                        child:
                            Text(e.eventType.isNotEmpty ? e.eventType : '—'))),
                    DataCell(
                        SizedBox(width: 120, child: Text(_fmtDate(e.date)))),
                    DataCell(SizedBox(
                        width: 120, child: Text(_fmtCreated(e.createdAt)))),
                    DataCell(SizedBox(
                        width: 170,
                        child: Text(
                            '${_fmtTimeOfDay(e.startTime)} - ${_fmtTimeOfDay(e.endTime)}'))),
                    DataCell(
                      SizedBox(
                        width: 120,
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
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Center(
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) => _handleAction(
                              context,
                              value: value,
                              e: e,
                              controller: controller,
                            ),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'view', child: Text('View')),
                              PopupMenuItem(value: 'copy', child: Text('Copy')),
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
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
    );
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
