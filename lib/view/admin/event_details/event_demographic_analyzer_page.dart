import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';

class EventDemographicAnalyzerPage extends StatefulWidget {
  final String eventId;
  final bool embedded;
  const EventDemographicAnalyzerPage({
    super.key,
    required this.eventId,
    this.embedded = false,
  });

  @override
  State<EventDemographicAnalyzerPage> createState() =>
      _EventDemographicAnalyzerPageState();
}

class _EventDemographicAnalyzerPageState
    extends State<EventDemographicAnalyzerPage> {
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

  List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, int> _asStringIntMap(dynamic v) {
    if (v is Map) {
      final out = <String, int>{};
      v.forEach((k, val) {
        out[(k ?? '').toString()] = _toInt(val);
      });
      return out;
    }
    return <String, int>{};
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
    final demo = _asMap(_data?['demographics']);
    final demoResponses = _toInt(demo['responses']);
    final demoQuestions = _asMapList(demo['questions'])
      ..sort((a, b) => _toInt(b['answeredCount']) - _toInt(a['answeredCount']));
    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demographic analyzer',
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
            ] else if (demoResponses == 0 || demoQuestions.isEmpty) ...[
              _emptyHint('No demographic responses yet.'),
            ] else ...[
              Row(
                children: [
                  Text('Demographic responses',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Text('$demoResponses responses',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: demoQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final q = demoQuestions[idx];
                  final qText = (q['questionText'] ?? 'Question').toString();
                  final type = (q['type'] ?? '').toString();
                  final answered = _toInt(q['answeredCount']);

                  final optionCounts = _asStringIntMap(q['optionCounts']);
                  final optionEntries = optionCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final isFreeText =
                      type == 'short_answer' || type == 'paragraph';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 10),
                      title: Text(qText,
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        isFreeText
                            ? 'Answered • $answered'
                            : (type == 'checkboxes'
                                ? 'Responded • $answered (multiple selections possible)'
                                : 'Answered • $answered'),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                      children: [
                        if (isFreeText) ...[
                          Text('Free-text question',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280))),
                        ] else if (optionEntries.isEmpty) ...[
                          _emptyHint('No options data for this question.'),
                        ] else ...[
                          ...optionEntries.take(12).map((e) {
                            final label = e.key.isEmpty ? '—' : e.key;
                            final count = e.value;

                            final denom = type == 'checkboxes'
                                ? optionEntries.fold<int>(
                                    0, (s, x) => s + x.value)
                                : answered;

                            return _barRow(
                                label: label,
                                count: count,
                                total: denom <= 0 ? 1 : denom);
                          }),
                        ],
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

  Widget _barRow(
      {required String label, required int count, required int total}) {
    final p = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    final pct = total <= 0 ? '—' : '${(p * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(child: _miniBar(value: count, total: total)),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text('$count • $pct',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}
