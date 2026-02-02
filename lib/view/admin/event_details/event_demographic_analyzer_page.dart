import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:universal_html/html.dart' as html;

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

class _DemoGuestDataSource extends DataTableSource {
  final List<Map<String, dynamic>> guests;

  final String Function(Map<String, dynamic>) nameOf;
  final String Function(Map<String, dynamic>) emailOf;

  // Download action per row (nullable)
  final VoidCallback? Function(Map<String, dynamic>) downloadActionOf;

  final TextStyle cellStyle;
  final TextStyle headStyle;

  final double nameW;
  final double emailW;
  final double actionW;

  _DemoGuestDataSource({
    required this.guests,
    required this.nameOf,
    required this.emailOf,
    required this.downloadActionOf,
    required this.cellStyle,
    required this.headStyle,
    required this.nameW,
    required this.emailW,
    required this.actionW,
  });

  Widget _cellText(String text, double w, {bool rightBorder = true}) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: rightBorder
              ? const BorderSide(color: Color(0xFFE5E7EB))
              : BorderSide.none,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: cellStyle,
      ),
    );
  }

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= guests.length) return null;
    final g = guests[index];

    final action = downloadActionOf(g);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(_cellText(nameOf(g), nameW)),
        DataCell(_cellText(emailOf(g), emailW)),
        DataCell(
          Container(
            width: actionW,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.center,
            child: IconButton(
              tooltip: action == null ? 'No answers' : 'Download answers',
              onPressed: action,
              icon: Icon(
                Icons.download_outlined,
                color: action == null
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => guests.length;

  @override
  int get selectedRowCount => 0;
}

class _EventDemographicAnalyzerPageState
    extends State<EventDemographicAnalyzerPage>
    with SingleTickerProviderStateMixin {
  late final CloudFunctionsService _svc;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  DateTime? _loadedAt;

  // ✅ Tabs: Questions / Guests
  TabController? _demoTabCtrl;

  // ✅ Searches
  final TextEditingController _questionSearchCtrl = TextEditingController();
  final TextEditingController _demoGuestSearchCtrl = TextEditingController();

  // ✅ Selected question ids (multi-select)
  final Set<String> _selectedQuestionIds = <String>{};

  // ✅ table paging
  int _guestFirstRowIndex = 0;
  final GlobalKey<PaginatedDataTableState> _guestTableKey =
      GlobalKey<PaginatedDataTableState>();

  // Button styles (matching your menu page feel)
  final outlineStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    visualDensity: VisualDensity.compact,
  );

  final primaryStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    visualDensity: VisualDensity.compact,
    elevation: 0,
  );

  ex.CellStyle _xlHeaderStyle() {
    return ex.CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      textWrapping: ex.TextWrapping.WrapText, // if not supported, remove line
    );
  }

  ex.CellStyle _xlCellStyle() {
    return ex.CellStyle(
      fontSize: 11,
      verticalAlign: ex.VerticalAlign.Top,
      horizontalAlign: ex.HorizontalAlign.Left,
      textWrapping: ex.TextWrapping.WrapText, // if not supported, remove line
    );
  }

  void _xlApplyStyleToRow(
      ex.Sheet sheet, int rowIndex, int colCount, ex.CellStyle style) {
    for (var c = 0; c < colCount; c++) {
      sheet
          .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex))
          .cellStyle = style;
    }
  }

  String _s(dynamic v) => (v ?? '').toString().trim();
  bool _has(dynamic v) => _s(v).isNotEmpty;

  @override
  void initState() {
    super.initState();
    _svc = Get.find<CloudFunctionsService>();

    _demoTabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _load();
  }

  @override
  void dispose() {
    _demoTabCtrl?.dispose();
    _questionSearchCtrl.dispose();
    _demoGuestSearchCtrl.dispose();
    super.dispose();
  }

  void _resetGuestTable() {
    setState(() => _guestFirstRowIndex = 0);
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _pct(int num, int den) {
    if (den <= 0) return 0;
    return (num / den) * 100.0;
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

  // ─────────────────────────────────────────────
  // Segmented tabs (Questions / Guests)
  // ─────────────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                    label: 'Questions',
                    icon: Icons.list_alt_outlined,
                  ),
                  const SizedBox(width: 6),
                  seg(
                    index: 1,
                    label: 'Guests',
                    icon: Icons.people_outline,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Search boxes
  // ─────────────────────────────────────────────
  Widget _questionSearchBox() {
    return TextField(
      controller: _questionSearchCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search demographic questions...',
        hintStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: _questionSearchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: () => setState(() => _questionSearchCtrl.clear()),
                icon: const Icon(Icons.close),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _guestSearchBox() {
    return TextField(
      controller: _demoGuestSearchCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search guest name or email...',
        hintStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: _demoGuestSearchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: () => setState(() => _demoGuestSearchCtrl.clear()),
                icon: const Icon(Icons.close),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Pills
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Dedupe guests safely
  // ─────────────────────────────────────────────
  String _demoGuestKey(Map<String, dynamic> g) {
    final inv = (g['invitationId'] ?? '').toString().trim();
    final guestId = (g['guestId'] ?? '').toString().trim();
    final ci = g['companionIndex'];
    final ciStr = (ci == null || ci.toString().trim().isEmpty)
        ? 'main'
        : ci.toString().trim();

    final email = (g['email'] ?? '').toString().trim().toLowerCase();
    final name = (g['name'] ?? '').toString().trim().toLowerCase();

    if (inv.isNotEmpty) return 'inv:$inv:$ciStr';
    if (guestId.isNotEmpty) return 'gid:$guestId:$ciStr';
    if (email.isNotEmpty && name.isNotEmpty) return 'emnm:$email:$name:$ciStr';
    if (email.isNotEmpty) return 'email:$email:$ciStr';
    return 'name:$name:$ciStr';
  }

  List<Map<String, dynamic>> _dedupeDemoGuests(
      List<Map<String, dynamic>> input) {
    final byKey = <String, Map<String, dynamic>>{};
    for (final g in input) {
      final key = _demoGuestKey(g);
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = Map<String, dynamic>.from(g);
        continue;
      }

      // merge answersByQid map
      final a = (existing['answersByQid'] is Map)
          ? Map<String, dynamic>.from(existing['answersByQid'])
          : <String, dynamic>{};
      final b = (g['answersByQid'] is Map)
          ? Map<String, dynamic>.from(g['answersByQid'])
          : <String, dynamic>{};
      a.addAll(b);
      existing['answersByQid'] = a;

      // prefer non-empty
      for (final f in [
        'name',
        'email',
        'invitationId',
        'guestId',
        'companionIndex'
      ]) {
        final cur = (existing[f] ?? '').toString().trim();
        final nxt = (g[f] ?? '').toString().trim();
        if (cur.isEmpty && nxt.isNotEmpty) existing[f] = g[f];
      }

      byKey[key] = existing;
    }
    return byKey.values.toList();
  }

  // ─────────────────────────────────────────────
  // Filter guests by selected questions
  // ─────────────────────────────────────────────
  bool _guestAnswersSelectedQuestions(Map<String, dynamic> g) {
    // if none selected -> show all guests
    if (_selectedQuestionIds.isEmpty) return true;

    final answersByQid = (g['answersByQid'] is Map)
        ? Map<String, dynamic>.from(g['answersByQid'])
        : <String, dynamic>{};

    for (final qid in _selectedQuestionIds) {
      final v = (answersByQid[qid] ?? '').toString().trim();
      if (v.isNotEmpty)
        return true; // guest answered at least one selected question
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // Exports
  // ─────────────────────────────────────────────
  Future<void> _exportGuestsAnswersToExcel({
    required List<Map<String, dynamic>> guests,
    required List<Map<String, dynamic>> questions,
  }) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Demographics'];

    ex.CellValue t(String v) => ex.TextCellValue(v);

    final headerStyle = _xlHeaderStyle();
    final cellStyle = _xlCellStyle();

    // choose questions: selected if any selected, else all
    final chosen = questions.where((q) {
      final qid = (q['questionId'] ?? '').toString().trim();
      if (qid.isEmpty) return false;
      if (_selectedQuestionIds.isEmpty) return true;
      return _selectedQuestionIds.contains(qid);
    }).toList();

    final qIds = <String>[];
    final header = <ex.CellValue?>[t('Name'), t('Email')];

    for (final q in chosen) {
      final qid = (q['questionId'] ?? '').toString().trim();
      final qText = (q['questionText'] ?? qid).toString().trim();

      qIds.add(qid);

      final headerText =
          qText.length > 45 ? '${qText.substring(0, 45)}…' : qText;
      header.add(t(headerText));
    }

    sheet.appendRow(header);
    _xlApplyStyleToRow(sheet, 0, header.length, headerStyle);

    int rowIndex = 1;
    for (final g in guests) {
      final answersByQid = (g['answersByQid'] is Map)
          ? Map<String, dynamic>.from(g['answersByQid'])
          : <String, dynamic>{};

      final row = <ex.CellValue?>[
        t((g['name'] ?? 'Guest').toString()),
        t((g['email'] ?? '—').toString()),
      ];

      for (final qid in qIds) {
        row.add(t((answersByQid[qid] ?? '').toString()));
      }

      sheet.appendRow(row);

      // apply normal style to entire row
      for (var c = 0; c < row.length; c++) {
        sheet
            .cell(ex.CellIndex.indexByColumnRow(
                columnIndex: c, rowIndex: rowIndex))
            .cellStyle = cellStyle;
      }
      rowIndex++;
    }

    if (excel.sheets.keys.contains('Sheet1') && excel.sheets.keys.length > 1) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'demographics_guests.xlsx')
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportSingleGuestAnswers({
    required Map<String, dynamic> guest,
    required List<Map<String, dynamic>> questions,
  }) async {
    final answersByQid = (guest['answersByQid'] is Map)
        ? Map<String, dynamic>.from(guest['answersByQid'])
        : <String, dynamic>{};

    final chosen = questions.where((q) {
      final qid = (q['questionId'] ?? '').toString().trim();
      if (qid.isEmpty) return false;
      if (_selectedQuestionIds.isEmpty) return true;
      return _selectedQuestionIds.contains(qid);
    }).toList();

    final excel = ex.Excel.createExcel();
    final sheet = excel['Answers'];

    ex.CellValue t(String v) => ex.TextCellValue(v);

    final headerStyle = _xlHeaderStyle();
    final cellStyle = _xlCellStyle();

    // Guest info rows
    final guestName = (guest['name'] ?? 'Guest').toString();
    final guestEmail = (guest['email'] ?? '—').toString();

    sheet.appendRow(<ex.CellValue?>[t('Guest Name'), t(guestName)]);
    sheet.appendRow(<ex.CellValue?>[t('Guest Email'), t(guestEmail)]);
    sheet.appendRow(<ex.CellValue?>[t(''), t('')]); // spacer

    // Header row
    sheet.appendRow(<ex.CellValue?>[t('Question'), t('Answer')]);
    _xlApplyStyleToRow(sheet, 3, 2, headerStyle);

    int rowIndex = 4;
    for (final q in chosen) {
      final qid = (q['questionId'] ?? '').toString().trim();
      final qText = (q['questionText'] ?? qid).toString().trim();
      final ans = (answersByQid[qid] ?? '').toString();

      sheet.appendRow(<ex.CellValue?>[t(qText), t(ans)]);

      sheet
          .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .cellStyle = cellStyle;
      sheet
          .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .cellStyle = cellStyle;

      rowIndex++;
    }

    // remove default sheet if present
    if (excel.sheets.keys.contains('Sheet1') && excel.sheets.keys.length > 1) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final safe = guestName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '')
        .trim()
        .replaceAll(' ', '_');
    final fileName =
        safe.isEmpty ? 'demographics_guest.xlsx' : 'demographics_$safe.xlsx';

    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  // ─────────────────────────────────────────────
  // UI helpers
  // ─────────────────────────────────────────────
  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
        ),
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

  String _prettyOptionLabel(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '—';

    // option_2 -> Option 2
    final m =
        RegExp(r'^option[_\s-]?(\d+)$', caseSensitive: false).firstMatch(s);
    if (m != null) return 'Option ${m.group(1)}';

    // replace underscores with spaces
    final cleaned =
        s.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // If it looks like a random id (very long, no spaces), keep as-is but it will ellipsize in UI.
    return cleaned;
  }

  // ─────────────────────────────────────────────
  // Questions list item (selectable)
  // ─────────────────────────────────────────────
  Widget _questionCard({
    required Map<String, dynamic> q,
    required int demoResponses,
  }) {
    final qid = (_s(q['questionId']) ?? '').toString();
    final qText = (q['questionText'] ?? 'Question').toString();
    final type = (q['type'] ?? '').toString();
    final answered = _toInt(q['answeredCount']);
    final isFreeText = type == 'short_answer' || type == 'paragraph';

    final pct = demoResponses <= 0 ? 0 : _pct(answered, demoResponses).round();

    final optionCounts = _asStringIntMap(q['optionCounts']);
    final optionEntries = optionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final selected = qid.isNotEmpty && _selectedQuestionIds.contains(qid);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.black : const Color(0xFFE5E7EB),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: qid.isEmpty
                ? null
                : () {
                    setState(() {
                      if (_selectedQuestionIds.contains(qid)) {
                        _selectedQuestionIds.remove(qid);
                      } else {
                        _selectedQuestionIds.add(qid);
                      }
                      _resetGuestTable();
                    });
                  },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFreeText
                            ? 'Answered • $answered ($pct%)'
                            : (type == 'checkboxes'
                                ? 'Responded • $answered (multiple selections possible)'
                                : 'Answered • $answered'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Icon(
                    selected ? Icons.check : Icons.add,
                    color: selected ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isFreeText)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Free-text answers • $pct%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            )
          else if (optionEntries.isEmpty)
            _emptyHint('No options data for this question.')
          else
            Column(
              children: optionEntries.take(12).map((e) {
                final label = _prettyOptionLabel(e.key);
                final count = e.value;

                final denom = type == 'checkboxes'
                    ? optionEntries.fold<int>(0, (s, x) => s + x.value)
                    : answered;

                return _barRow(
                  label: label,
                  count: count,
                  total: denom <= 0 ? 1 : denom,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _barRow({
    required String label,
    required int count,
    required int total,
  }) {
    final p = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    final pct = total <= 0 ? '—' : '${(p * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _miniBar(value: count, total: total)),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              '$count • $pct',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Guests table section (same look as menu)
  // ─────────────────────────────────────────────
  Widget _guestTableSection({
    required List<Map<String, dynamic>> guests,
    required List<Map<String, dynamic>> questions,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    final headingFs = w < 900 ? 18.0 : 20.0;

    final selectedCount = _selectedQuestionIds.length;
    final hasSelection = selectedCount > 0;

    final deduped = _dedupeDemoGuests(guests)
      ..sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
            (b['name'] ?? '').toString().toLowerCase(),
          ));

    final visible = deduped.where(_guestAnswersSelectedQuestions).toList();

    final gq = _demoGuestSearchCtrl.text.trim().toLowerCase();
    final filtered = visible.where((g) {
      if (gq.isEmpty) return true;
      final n = (g['name'] ?? '').toString().toLowerCase();
      final e = (g['email'] ?? '').toString().toLowerCase();
      return n.contains(gq) || e.contains(gq);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Guest list',
                style: GoogleFonts.poppins(
                  fontSize: headingFs,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _pill('${filtered.length} guests'),
              if (hasSelection)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$selectedCount questions selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                _pill('All questions'),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: outlineStyle,
                  onPressed: filtered.isEmpty
                      ? null
                      : () => _exportGuestsAnswersToExcel(
                            guests: filtered,
                            questions: questions,
                          ),
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: Text(
                    'Export Excel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: _selectedQuestionIds.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selectedQuestionIds.clear();
                            _resetGuestTable();
                          });
                        },
                  child: Text(
                    'Clear selection',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _guestSearchBox(),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _emptyHint(hasSelection
                ? 'No guests answered the selected questions.'
                : 'No guests found.')
          else
            _guestDataTable(filtered, questions),
        ],
      ),
    );
  }

  Widget _guestDataTable(
    List<Map<String, dynamic>> guests,
    List<Map<String, dynamic>> questions,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableW = constraints.maxWidth;

        final baseFs = tableW < 700
            ? 13.0
            : tableW < 1100
                ? 14.0
                : 15.0;

        final headStyle = GoogleFonts.poppins(
          fontSize: baseFs + 1,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        );

        final cellStyle = GoogleFonts.poppins(
          fontSize: baseFs,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        );

        final actionW = 120.0;
        final nameW = (tableW * 0.30).clamp(170.0, 360.0);
        final emailW = (tableW - nameW - actionW).clamp(240.0, 620.0);

        Widget headCell(String text, double w, {bool rightBorder = true}) {
          return Container(
            width: w,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                right: rightBorder
                    ? const BorderSide(color: Color(0xFFE5E7EB))
                    : BorderSide.none,
              ),
            ),
            child: Text(text, style: headStyle),
          );
        }

        final src = _DemoGuestDataSource(
          guests: guests,
          nameOf: (g) => (g['name'] ?? 'Guest').toString(),
          emailOf: (g) => (g['email'] ?? '—').toString(),
          downloadActionOf: (g) {
            final answersByQid = (g['answersByQid'] is Map)
                ? Map<String, dynamic>.from(g['answersByQid'])
                : <String, dynamic>{};

            // No answers
            if (answersByQid.isEmpty) return null;

            // If selection exists, ensure guest has something for at least one selected q
            if (_selectedQuestionIds.isNotEmpty) {
              bool any = false;
              for (final qid in _selectedQuestionIds) {
                final v = (answersByQid[qid] ?? '').toString().trim();
                if (v.isNotEmpty) {
                  any = true;
                  break;
                }
              }
              if (!any) return null;
            }

            return () => _exportSingleGuestAnswers(
                  guest: g,
                  questions: questions,
                );
          },
          cellStyle: cellStyle,
          headStyle: headStyle,
          nameW: nameW,
          emailW: emailW,
          actionW: actionW,
        );

        final isNarrow = tableW < 900;
        final rowsPerPage = isNarrow ? 5 : 10;
        final safeIndex = guests.isEmpty
            ? 0
            : _guestFirstRowIndex.clamp(0, guests.length - 1);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Theme(
              data: Theme.of(context).copyWith(
                cardTheme: const CardThemeData(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: Colors.transparent,
                ),
                dividerColor: const Color(0xFFE5E7EB),
              ),
              child: PaginatedDataTable(
                key: _guestTableKey,
                initialFirstRowIndex: safeIndex,
                onPageChanged: (i) => setState(() => _guestFirstRowIndex = i),
                headingRowColor:
                    MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                header: null,
                showCheckboxColumn: false,
                rowsPerPage: rowsPerPage,
                availableRowsPerPage: const <int>[5, 10, 20],
                horizontalMargin: 0,
                columnSpacing: 0,
                headingRowHeight: 46,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 58,
                columns: [
                  DataColumn(label: headCell('Name', nameW)),
                  DataColumn(label: headCell('Email', emailW)),
                  DataColumn(
                      label: headCell('Download', actionW, rightBorder: false)),
                ],
                source: src,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final demo = _asMap(_data?['demographics']);
    final demoResponses = _toInt(demo['responses']);
    final demoQuestions = _asMapList(demo['questions'])
      ..sort((a, b) => _toInt(b['answeredCount']) - _toInt(a['answeredCount']));
    final demoGuestResponses = _asMapList(demo['guestResponses']);

    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

    final tabCtrl = _demoTabCtrl;
    final isQuestionsTab = (tabCtrl?.index ?? 0) == 0;

    // Questions search
    final qSearch = _questionSearchCtrl.text.trim().toLowerCase();
    final visibleQuestions = demoQuestions.where((q) {
      if (qSearch.isEmpty) return true;
      final t = (q['questionText'] ?? '').toString().toLowerCase();
      return t.contains(qSearch);
    }).toList();

    final outerChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demographic analyzer',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
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
          ],
        ),

        const SizedBox(height: 12),

        if (_loading) ...[
          Text(
            'Loading analytics...',
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 3),
        ] else if (_error != null) ...[
          Text(
            'Failed to load',
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _error!,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text('Try again', style: GoogleFonts.poppins()),
          ),
        ] else if (demoResponses == 0 || demoQuestions.isEmpty) ...[
          _emptyHint('No demographic responses yet.'),
        ] else ...[
          Row(
            children: [
              Text(
                'Demographic responses',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Text(
                '$demoResponses responses',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF6B7280)),
              ),
              const Spacer(),
              if (_selectedQuestionIds.isNotEmpty)
                _pill('${_selectedQuestionIds.length} selected'),
            ],
          ),
          const SizedBox(height: 12),
          if (tabCtrl != null) _segmentedTabs(tabCtrl),
          const SizedBox(height: 14),
          if (isQuestionsTab) ...[
            _questionSearchBox(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed: visibleQuestions.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedQuestionIds
                                ..clear()
                                ..addAll(
                                  visibleQuestions
                                      .map((q) => (_s(q['questionId']) ?? '')
                                          .toString())
                                      .where((s) => s.isNotEmpty),
                                );
                              _resetGuestTable();
                            });
                          },
                    child: Text('Select all',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: _selectedQuestionIds.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedQuestionIds.clear();
                              _resetGuestTable();
                            });
                          },
                    child: Text('Clear selection',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (visibleQuestions.isEmpty)
              _emptyHint('No questions match your search.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  return _questionCard(
                    q: visibleQuestions[idx],
                    demoResponses: demoResponses,
                  );
                },
              ),
          ] else ...[
            _guestTableSection(
              guests: demoGuestResponses,
              questions: demoQuestions,
            ),
          ],
        ],
      ],
    );

    // embedded vs standalone container
    if (widget.embedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: outerChild,
      );
    }

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
        child: outerChild,
      ),
    );
  }
}
