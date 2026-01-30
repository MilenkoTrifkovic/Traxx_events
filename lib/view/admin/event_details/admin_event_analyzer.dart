import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';

class AdminEventAnalyzerPage extends StatefulWidget {
  final String eventId;
  const AdminEventAnalyzerPage({super.key, required this.eventId});

  @override
  State<AdminEventAnalyzerPage> createState() => _AdminEventAnalyzerPageState();
}

class _AdminEventAnalyzerPageState extends State<AdminEventAnalyzerPage> {
  late final CloudFunctionsService _svc;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  DateTime? _loadedAt;

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

    return TooltipVisibility(
      visible: false, // ✅ prevents web tooltip overlay crash
      child: SingleChildScrollView(
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
                Text(
                  'Analyze responses',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 920;

                    final demoCard = _demographicAnalyzerNavCard(
                      responses: demoResponses,
                      onTap: () => context.push(
                        '/event-details/${widget.eventId}/demographic-analyzer',
                      ),
                    );

                    final menuCard = _menuItemsAnalyzerNavCard(
                      responses: menuResponses,
                      onTap: () => context.push(
                        '/event-details/${widget.eventId}/menu-analyzer',
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          demoCard,
                          const SizedBox(height: 12),
                          menuCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: demoCard),
                        const SizedBox(width: 14),
                        Expanded(child: menuCard),
                      ],
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

  // ✅ separate card for Demographic analyzer
  Widget _demographicAnalyzerNavCard({
    required int responses,
    required VoidCallback onTap,
  }) {
    return _baseAnalyzerNavCard(
      title: 'Demographic analyzer',
      subtitle: responses == 0 ? 'No responses yet' : '$responses responses',
      icon: Icons.assignment_outlined,
      pillText: 'View',
      onTap: onTap,
    );
  }

  // ✅ separate card for Menu items analyzer
  Widget _menuItemsAnalyzerNavCard({
    required int responses,
    required VoidCallback onTap,
  }) {
    return _baseAnalyzerNavCard(
      title: 'Menu items analyzer',
      subtitle: responses == 0 ? 'No selections yet' : '$responses responses',
      icon: Icons.restaurant_menu,
      pillText: 'View',
      onTap: onTap,
    );
  }

  // shared base UI
  Widget _baseAnalyzerNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String pillText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(icon, size: 22, color: const Color(0xFF111827)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pillText,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
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
