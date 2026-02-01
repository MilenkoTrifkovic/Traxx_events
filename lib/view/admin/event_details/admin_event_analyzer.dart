import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/view/admin/event_details/event_demographic_analyzer_page.dart';
import 'package:traxx_wepapp/view/admin/event_details/event_menu_analyzer_page.dart';

class AdminEventAnalyzerPage extends StatefulWidget {
  final String eventId;
  const AdminEventAnalyzerPage({super.key, required this.eventId});

  @override
  State<AdminEventAnalyzerPage> createState() => _AdminEventAnalyzerPageState();
}

class _AdminEventAnalyzerPageState extends State<AdminEventAnalyzerPage>
    with SingleTickerProviderStateMixin {
  late final CloudFunctionsService _svc;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  DateTime? _loadedAt;

  TabController? _tabCtrl;

  @override
  void initState() {
    super.initState();
    _svc = Get.find<CloudFunctionsService>();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _svc.getEventAnalytics(eventId: widget.eventId);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loadedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _segmentedTabs(TabController ctrl) {
    return LayoutBuilder(
      builder: (context, c) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final isNarrow = c.maxWidth < 520;
        final maxW = isNarrow ? c.maxWidth : 520.0;

        final shellBg = isDark ? cs.surface.withOpacity(0.65) : cs.surface;
        final shellBorder = cs.outline.withOpacity(isDark ? 0.45 : 0.22);

        final selGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.secondary],
        );

        Widget seg({
          required int index,
          required String label,
          required IconData icon,
        }) {
          final selected = (ctrl.index == index);

          final child = AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? selGrad : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(isDark ? 0.25 : 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ],
            ),
          );

          final tappable = InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ctrl.animateTo(index),
            child: child,
          );

          return isNarrow ? Expanded(child: Center(child: tappable)) : tappable;
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: shellBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: shellBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  seg(
                      index: 0,
                      label: "Demographics",
                      icon: Icons.assignment_outlined),
                  const SizedBox(width: 6),
                  seg(index: 1, label: "Menu", icon: Icons.restaurant_menu),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = _asMap(_data?['invitations']);
    final demo = _asMap(_data?['demographics']);
    final menu = _asMap(_data?['menu']);

    final totalInv = _toInt(inv['total']);
    final sent = _toInt(inv['sent']);
    final demoDone = _toInt(inv['demographicsSubmitted']);
    final menuDone = _toInt(inv['menuSubmitted']);

    final demoResponses = _toInt(demo['responses']);
    final menuResponses = _toInt(menu['responses']);

    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

    final tabCtrl = _tabCtrl;

    return TooltipVisibility(
      visible: false, // ✅ keeps web tooltip crashes away
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event analyzer',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (lastUpdated != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Updated • $lastUpdated',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_loading) ...[
                Text(
                  'Loading analytics...',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 3),
              ] else if (_error != null) ...[
                Text(
                  'Failed to load analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text('Try again', style: GoogleFonts.poppins()),
                  ),
                ),
              ] else ...[
                Text(
                  'Completion funnel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statTile('Invited', totalInv, totalInv),
                    _statTile('Emails sent', sent, totalInv),
                    _statTile('Demographics done', demoDone, totalInv),
                    _statTile('Menu done', menuDone, totalInv),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // ✅ Tabs instead of nav cards
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Analyze responses',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _pill(demoResponses == 0
                        ? 'No demo yet'
                        : '$demoResponses demo'),
                    const SizedBox(width: 8),
                    _pill(menuResponses == 0
                        ? 'No menu yet'
                        : '$menuResponses menu'),
                  ],
                ),
                const SizedBox(height: 12),

                if (tabCtrl != null) _segmentedTabs(tabCtrl),
                const SizedBox(height: 14),

                // ✅ Tab content fills remaining height; each tab page can scroll internally
                // ✅ Give TabBarView a real bounded height (prevents unbounded flex error)
                LayoutBuilder(
                  builder: (context, c) {
                    final screenH = MediaQuery.sizeOf(context).height;

                    // A good height that works on desktop + mobile
                    // (You can tweak 0.72 -> 0.80 depending on how tall you want it)
                    final h = (screenH * 0.72).clamp(520.0, 900.0);

                    return SizedBox(
                      height: h,
                      child: TabBarView(
                        controller: tabCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          EventDemographicAnalyzerPage(
                              eventId: widget.eventId, embedded: true),
                          EventMenuAnalyzerPage(
                              eventId: widget.eventId, embedded: true),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _statTile(String label, int value, int total) {
    final pct = (total <= 0) ? 0 : (value / total);
    final pctText = total <= 0 ? '—' : '${(pct * 100).round()}%';

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$value',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                pctText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniBar(value: value, total: total <= 0 ? 1 : total),
        ],
      ),
    );
  }

  Widget _miniBar({required int value, required int total}) {
    final p = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: const Color(0xFFE5E7EB),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: p,
            child: Container(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
