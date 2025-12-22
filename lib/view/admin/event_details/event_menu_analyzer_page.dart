import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';

class EventMenuAnalyzerPage extends StatefulWidget {
  final String eventId;
  const EventMenuAnalyzerPage({super.key, required this.eventId});

  @override
  State<EventMenuAnalyzerPage> createState() => _EventMenuAnalyzerPageState();
}

class _EventMenuAnalyzerPageState extends State<EventMenuAnalyzerPage> {
  late final CloudFunctionsService _svc;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  DateTime? _loadedAt;

  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _svc = Get.find<CloudFunctionsService>();
    _load();
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

  List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
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

  @override
  Widget build(BuildContext context) {
    final menu = _asMap(_data?['menu']);
    final menuResponses = _toInt(menu['responses']);
    final menuItems = _asMapList(menu['items'])
      ..sort((a, b) => _toInt(b['count']) - _toInt(a['count']));
    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

    final shownCount = _showAll
        ? menuItems.length
        : (menuItems.length > 10 ? 10 : menuItems.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
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
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Menu items analyzer',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      if (lastUpdated != null) ...[
                        const SizedBox(height: 2),
                        Text('Updated • $lastUpdated',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: const Color(0xFF6B7280))),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_loading) ...[
              Text('Loading analytics...',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF6B7280))),
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 3),
            ] else if (_error != null) ...[
              Text('Failed to load',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_error!,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.red.shade700)),
              const SizedBox(height: 10),
              TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text('Try again', style: GoogleFonts.poppins())),
            ] else if (menuResponses == 0 || menuItems.isEmpty) ...[
              _emptyHint('No menu selections yet.'),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text('Menu item responses',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Text('$menuResponses responses',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(_showAll ? 'Show top 10' : 'Show all',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shownCount,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final it = menuItems[idx];
                  final name = (it['name'] ?? 'Menu item').toString();
                  final count = _toInt(it['count']);
                  final cat = (it['category'] ?? '').toString();
                  final isVeg = it['isVeg'];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text('$count',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (cat.isNotEmpty)
                              Text(cat,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280))),
                            if (cat.isNotEmpty && isVeg != null)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('•',
                                    style: TextStyle(color: Color(0xFFCBD5E1))),
                              ),
                            if (isVeg is bool)
                              Text(isVeg ? 'Veg' : 'Non-Veg',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _miniBar(value: count, total: menuResponses),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 12, color: const Color(0xFF6B7280))),
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
              widthFactor: p, child: Container(color: Colors.black)),
        ),
      ),
    );
  }
}
