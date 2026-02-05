import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:universal_html/html.dart' as html;

class FoodMeta {
  final String label;
  final IconData icon;
  final Color color;

  const FoodMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

enum DietFilter { all, veg, nonVeg }

enum GuestDietType { all, veg, nonVeg, both }

class EventMenuAnalyzerPage extends StatefulWidget {
  final String eventId;
  final bool embedded;
  const EventMenuAnalyzerPage({
    super.key,
    required this.eventId,
    this.embedded = false,
  });

  @override
  State<EventMenuAnalyzerPage> createState() => _EventMenuAnalyzerPageState();
}

class _GuestDataSource extends DataTableSource {
  final List<Map<String, dynamic>> guests;

  final String Function(Map<String, dynamic>) nameOf;
  final String Function(Map<String, dynamic>) emailOf;

  // ✅ Diet widget (colored chip)
  final Widget Function(Map<String, dynamic>) dietWidgetOf;

  // ✅ Download action per row (nullable)
  final VoidCallback? Function(Map<String, dynamic>) downloadActionOf;

  final TextStyle cellStyle;
  final TextStyle headStyle;

  final double nameW;
  final double emailW;
  final double dietW;
  final double actionW;

  _GuestDataSource({
    required this.guests,
    required this.nameOf,
    required this.emailOf,
    required this.dietWidgetOf,
    required this.downloadActionOf,
    required this.cellStyle,
    required this.headStyle,
    required this.nameW,
    required this.emailW,
    required this.dietW,
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

  Widget _cellWidget(Widget child, double w, {bool rightBorder = true}) {
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
      alignment: Alignment.centerLeft,
      child: child,
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
        DataCell(_cellWidget(dietWidgetOf(g), dietW)),
        DataCell(
          Container(
            width: actionW,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.center,
            child: IconButton(
              tooltip: action == null
                  ? 'No menu selected'
                  : 'Download selected menu',
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

class _EventMenuAnalyzerPageState extends State<EventMenuAnalyzerPage>
    with SingleTickerProviderStateMixin {
  late final CloudFunctionsService _svc;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  DateTime? _loadedAt;

  bool _showAll = false;

  // ✅ Use nullable controller to prevent LateInitializationError entirely.
  TabController? _tabCtrl;

  // ✅ Filters
  DietFilter _dietFilter = DietFilter.all;
  GuestDietType _guestDietType = GuestDietType.all;

  // ✅ Menu item search
  final TextEditingController _menuSearchCtrl = TextEditingController();

  // ✅ Multi select menu items
  final Set<String> _selectedMenuItemIds = <String>{};

  // ✅ Guest search
  final TextEditingController _guestSearchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedGuest;
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
  int _guestFirstRowIndex = 0;
  final GlobalKey<PaginatedDataTableState> _guestTableKey =
      GlobalKey<PaginatedDataTableState>();

  String _guestDietExcelLabel(Map<String, dynamic> g) {
    final t = _dietTypeFromGuest(g);
    if (t == GuestDietType.veg) return 'Veg';
    if (t == GuestDietType.nonVeg) return 'Non-Veg';
    if (t == GuestDietType.both) return 'Both';
    return 'Unknown';
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  bool _matchesGuestDiet(Map<String, dynamic> g) {
    if (_guestDietType == GuestDietType.all) return true;

    var dt = (g['dietType'] ?? g['dietPreference'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    dt = dt.replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');

    if (_guestDietType == GuestDietType.veg) {
      return dt == 'veg' || dt == 'vegetarian';
    }
    if (_guestDietType == GuestDietType.nonVeg) {
      return dt == 'nonveg' || dt == 'nonvegetarian' || dt.startsWith('non');
    }
    if (_guestDietType == GuestDietType.both) {
      return dt == 'both';
    }
    return true;
  }

  String _menuItemId(Map<String, dynamic> m) {
    return (m['id'] ?? m['menuItemId'] ?? m['menuItemID'] ?? '')
        .toString()
        .trim();
  }

  String _guestKey(Map<String, dynamic> g) {
    final inv = (g['invitationId'] ?? '').toString().trim();
    final ci = g['companionIndex'];
    final ciStr = (ci == null || ci.toString().trim().isEmpty)
        ? 'main'
        : ci.toString().trim();
    if (inv.isNotEmpty) return '$inv:$ciStr';

    final email =
        (g['email'] ?? g['guestEmail'] ?? '').toString().trim().toLowerCase();
    if (email.isNotEmpty) return 'email:$email:$ciStr';

    final name =
        (g['name'] ?? g['guestName'] ?? '').toString().trim().toLowerCase();
    return 'name:$name:$ciStr';
  }

  String _safeName(Map<String, dynamic> g) {
    final s = (g['name'] ?? g['guestName'] ?? '').toString().trim();
    if (s.isNotEmpty) return s;
    final em = (g['email'] ?? g['guestEmail'] ?? '').toString().trim();
    return em.isNotEmpty ? em : 'Guest';
  }

  String _safeEmail(Map<String, dynamic> g) {
    final s = (g['email'] ?? g['guestEmail'] ?? '').toString().trim();
    return s.isEmpty ? '—' : s;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _safeFileName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim();
    return cleaned.isEmpty ? 'file' : cleaned.replaceAll(' ', '_');
  }

  List<Map<String, dynamic>> _guestsForMenuItem(
    String itemId,
    List<Map<String, dynamic>> guestSelections,
  ) {
    if (itemId.trim().isEmpty) return const [];

    // ✅ filter guests who selected this item
    final raw = guestSelections.where((g) {
      final ids = _asStringSet(g['selectedMenuItemIds']);
      return ids.contains(itemId);
    }).toList();

    // ✅ dedupe by invitationId/companionIndex/email fallback
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    for (final g in raw) {
      final key = _guestKey(g);
      if (seen.add(key)) out.add(g);
    }

    out.sort((a, b) =>
        _safeName(a).toLowerCase().compareTo(_safeName(b).toLowerCase()));
    return out;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
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

  List<Map<String, dynamic>> _asGuestSelections(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((m) {
        final n = (m['name'] ?? m['guestName'] ?? '').toString().trim();
        final em = (m['email'] ?? m['guestEmail'] ?? '').toString().trim();
        return n.isNotEmpty || em.isNotEmpty;
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Set<String> _asStringSet(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  String _prettyCategory(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 'Other';

    final spaced = s
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  GuestDietType _dietTypeFromGuest(Map<String, dynamic> g) {
    var dt = (g['dietType'] ?? g['dietPreference'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    dt = dt.replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');

    if (dt == 'both') return GuestDietType.both;
    if (dt == 'nonveg' || dt == 'nonvegetarian' || dt.startsWith('non'))
      return GuestDietType.nonVeg;
    if (dt == 'veg' || dt == 'vegetarian') return GuestDietType.veg;
    return GuestDietType.all; // unknown/other
  }

  DietCounts countDiet(List<Map<String, dynamic>> guests) {
    int veg = 0, nonVeg = 0, both = 0, unknown = 0;
    for (final g in guests) {
      final t = _dietTypeFromGuest(g);
      if (t == GuestDietType.veg)
        veg++;
      else if (t == GuestDietType.nonVeg)
        nonVeg++;
      else if (t == GuestDietType.both)
        both++;
      else
        unknown++;
    }
    return DietCounts(veg: veg, nonVeg: nonVeg, both: both, unknown: unknown);
  }

  String _displayGuestKey(Map<String, dynamic> g) {
    final inv = (g['invitationId'] ?? '').toString().trim();
    final guestId = (g['guestId'] ?? '').toString().trim();

    final email =
        (g['email'] ?? g['guestEmail'] ?? '').toString().trim().toLowerCase();
    final name =
        (g['name'] ?? g['guestName'] ?? '').toString().trim().toLowerCase();

    final ci = g['companionIndex'];
    final ciStr = (ci == null || ci.toString().trim().isEmpty)
        ? 'main'
        : ci.toString().trim();

    // ✅ strongest keys first
    if (inv.isNotEmpty) return 'inv:$inv:$ciStr';
    if (guestId.isNotEmpty) return 'gid:$guestId:$ciStr';

    // ✅ same email can exist for different names -> include both
    if (email.isNotEmpty && name.isNotEmpty) return 'emnm:$email:$name:$ciStr';
    if (email.isNotEmpty) return 'email:$email:$ciStr';

    return 'name:$name:$ciStr';
  }

  List<Map<String, dynamic>> _dedupeGuests(List<Map<String, dynamic>> input) {
    final byKey = <String, Map<String, dynamic>>{};

    for (final g in input) {
      final key = _displayGuestKey(g);
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = Map<String, dynamic>.from(g);
        continue;
      }

      // merge selectedMenuItemIds (union)
      final a = _asStringSet(existing['selectedMenuItemIds']);
      final b = _asStringSet(g['selectedMenuItemIds']);
      existing['selectedMenuItemIds'] = <String>{...a, ...b}.toList();

      // fill blanks
      for (final f in [
        'invitationId',
        'guestId',
        'name',
        'guestName',
        'email',
        'guestEmail',
        'gender',
        'dietType',
        'dietPreference',
        'address',
        'city',
        'state',
        'country',
        'companionIndex',
      ]) {
        final cur = (existing[f] ?? '').toString().trim();
        final nxt = (g[f] ?? '').toString().trim();
        if (cur.isEmpty && nxt.isNotEmpty) existing[f] = g[f];
      }

      byKey[key] = existing;
    }

    return byKey.values.toList();
  }

  FoodMeta _foodMeta(bool? isVeg, String? foodType) {
    final ft = (foodType ?? '').trim().toLowerCase();

    if (ft.isNotEmpty) {
      final norm =
          ft.replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');

      if (norm == 'veg' || norm == 'vegetarian') {
        return FoodMeta(
          label: 'Veg',
          icon: Icons.eco_outlined,
          color: Colors.green.shade700,
        );
      }

      if (norm == 'nonveg' || norm == 'nonvegetarian' || ft.contains('non')) {
        return FoodMeta(
          label: 'Non-Veg',
          icon: Icons.set_meal_outlined,
          color: Colors.red.shade700,
        );
      }
    }

    if (isVeg == true) {
      return FoodMeta(
        label: 'Veg',
        icon: Icons.eco_outlined,
        color: Colors.green.shade700,
      );
    }

    if (isVeg == false) {
      return FoodMeta(
        label: 'Non-Veg',
        icon: Icons.set_meal_outlined,
        color: Colors.red.shade700,
      );
    }

    return FoodMeta(
      label: '—',
      icon: Icons.help_outline,
      color: Colors.grey.shade700,
    );
  }

  bool _matchesDiet(Map<String, dynamic> item) {
    if (_dietFilter == DietFilter.all) return true;

    final isVeg = item['isVeg'] is bool ? (item['isVeg'] as bool) : null;
    final ft = (item['foodType'] ?? '').toString().trim();
    final food = _foodMeta(isVeg, ft.isEmpty ? null : ft);

    if (_dietFilter == DietFilter.veg) return food.label == 'Veg';
    if (_dietFilter == DietFilter.nonVeg) return food.label == 'Non-Veg';
    return true;
  }

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl!.addListener(() {
      if (mounted) setState(() {});
    });

    _svc = Get.find<CloudFunctionsService>();
    _load();
  }

  @override
  void dispose() {
    _menuSearchCtrl.dispose();
    _guestSearchCtrl.dispose();
    _tabCtrl?.dispose();
    super.dispose();
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
  // Exports
  // ─────────────────────────────────────────────
  Future<void> _exportGuestsToExcel(
    List<Map<String, dynamic>> guests, {
    String fileName = 'guest_list.xlsx',
  }) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Guests'];
    ex.CellValue t(String v) => ex.TextCellValue(v);

    // Header
    sheet.appendRow(<ex.CellValue?>[
      t('Guest Name'),
      t('Guest Email'),
    ]);

    final headerStyle = ex.CellStyle(bold: true, fontSize: 12);
    sheet
        .cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = headerStyle;
    sheet
        .cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .cellStyle = headerStyle;

    for (final g in guests) {
      sheet.appendRow(<ex.CellValue?>[
        t(_safeName(g)),
        t(_safeEmail(g)),
      ]);
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
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportGuestsMenuMatrixToExcel(
    List<Map<String, dynamic>> guests,
    List<Map<String, dynamic>> allMenuItems, {
    String fileName = 'guest_menu_matrix.xlsx',
  }) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Guests Menu'];

    ex.CellValue t(String v) => ex.TextCellValue(v);

    final headerStyle = ex.CellStyle(bold: true, fontSize: 12);
    final guestNameStyle = ex.CellStyle(bold: true, fontSize: 11);

    // ✅ id -> menu item lookup
    final byId = <String, Map<String, dynamic>>{};
    for (final m in allMenuItems) {
      final id = _menuItemId(m);
      if (id.isNotEmpty) byId[id] = m;
    }

    // ✅ collect unique categories from event menu items
    final catSet = <String>{};
    for (final m in allMenuItems) {
      final raw = (m['categoryLabel'] ?? m['category'] ?? 'Other').toString();
      final cat = _prettyCategory(raw);
      if (cat.trim().isNotEmpty) catSet.add(cat);
    }

    // stable order (you can change sorting later if you want fixed custom order)
    final categories = catSet.toList()..sort();

    // ✅ header: Guest Name, Diet, then categories
    final headerTitles = <String>[
      'Guest Name',
      'Veg/non- Veg/Both',
      ...categories,
    ];

    sheet.appendRow(headerTitles.map(t).toList());

    // bold header
    for (int c = 0; c < headerTitles.length; c++) {
      sheet
          .cell(ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    int rowIndex = 1;

    for (final g in guests) {
      final guestName = _safeName(g);
      final diet =
          _guestDietExcelLabel(g); // Veg / Non-Veg / Veg & Non-veg / Unknown

      // category -> items
      final Map<String, List<String>> catToItems = {};

      final ids = _asStringSet(g['selectedMenuItemIds']);
      for (final id in ids) {
        final m = byId[id];
        if (m == null) continue;

        final rawCat =
            (m['categoryLabel'] ?? m['category'] ?? 'Other').toString();
        final cat = _prettyCategory(rawCat);

        final itemName = (m['name'] ?? '').toString().trim();
        if (itemName.isEmpty) continue;

        catToItems.putIfAbsent(cat, () => []);
        catToItems[cat]!.add(itemName);
      }

      // sort items inside each category
      for (final cat in catToItems.keys) {
        catToItems[cat]!.sort();
      }

      // build row aligned with header
      final row = <ex.CellValue?>[
        t(guestName),
        t(diet),
      ];

      for (final cat in categories) {
        final itemsText = (catToItems[cat] ?? const <String>[]).join(', ');
        row.add(t(itemsText));
      }

      sheet.appendRow(row);

      // bold guest name cell
      sheet
          .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .cellStyle = guestNameStyle;

      rowIndex++;
    }

    // remove default
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
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportMenuItemsToExcel(
    List<Map<String, dynamic>> items, {
    required int totalResponses,
  }) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Menu Items'];
    ex.CellValue t(String v) => ex.TextCellValue(v);

    final headerStyle = ex.CellStyle(bold: true, fontSize: 12);
    final nameBoldStyle = ex.CellStyle(bold: true, fontSize: 11);

    // ✅ Header row
    sheet.appendRow(<ex.CellValue?>[
      t('Name'),
      t('Category'),
      t('Food Type'),
      t('Price'),
      t('No. of Guests Selected'),
      t('Percent'),
    ]);

    // ✅ Make header bold (row 0, all columns 0..5)
    for (int c = 0; c < 6; c++) {
      sheet
          .cell(ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    final sorted = [...items]
      ..sort((a, b) => _toInt(b['count']) - _toInt(a['count']));

    int rowIndex = 1;

    for (final m in sorted) {
      final name = (m['name'] ?? '').toString().trim();
      final category = _prettyCategory(
          (m['categoryLabel'] ?? m['category'] ?? '').toString());
      final isVeg = m['isVeg'] is bool ? (m['isVeg'] as bool) : null;
      final foodTypeRaw = (m['foodType'] ?? '').toString().trim();
      final food = _foodMeta(isVeg, foodTypeRaw.isEmpty ? null : foodTypeRaw);

      final price = _toDouble(m['price']);
      final count = _toInt(m['count']);
      final pct =
          totalResponses <= 0 ? 0 : ((count / totalResponses) * 100).round();

      sheet.appendRow(<ex.CellValue?>[
        t(name.isEmpty ? '—' : name),
        t(category.isEmpty ? 'Other' : category),
        t(food.label),
        t(price == null ? '—' : '\$${price.toStringAsFixed(0)}'),
        t('$count'),
        t('$pct%'),
      ]);

      // ✅ Make menu item name bold (column 0 for this row)
      sheet
          .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .cellStyle = nameBoldStyle;

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
      ..setAttribute('download', 'menu_items.xlsx')
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportSelectedMenuForGuest({
    required Map<String, dynamic> guest,
    required List<Map<String, dynamic>> allMenuItems,
  }) async {
    final ids = _asStringSet(guest['selectedMenuItemIds']);
    if (ids.isEmpty) return;

    final byId = <String, Map<String, dynamic>>{};
    for (final m in allMenuItems) {
      final id = _menuItemId(m);
      if (id.isNotEmpty) byId[id] = m;
    }

    final selectedItems = ids
        .map((id) => byId[id])
        .where((m) => m != null)
        .cast<Map<String, dynamic>>()
        .toList();

    final excel = ex.Excel.createExcel();
    final sheet = excel['Selected Menu'];

    ex.CellValue t(String v) => ex.TextCellValue(v);

    final headerStyle = ex.CellStyle(bold: true, fontSize: 12);
    final itemBoldStyle = ex.CellStyle(bold: true, fontSize: 11);

    // ✅ Header
    sheet.appendRow(<ex.CellValue?>[
      t('Item'),
      t('Category'),
      t('Food Type'),
      t('Price'),
    ]);

    // ✅ Bold header cells (row 0)
    for (int c = 0; c < 4; c++) {
      sheet
          .cell(ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    int rowIndex = 1;

    for (final m in selectedItems) {
      final name = (m['name'] ?? '').toString().trim();
      final category = _prettyCategory(
        (m['categoryLabel'] ?? m['category'] ?? '').toString(),
      );

      // ✅ Use _foodMeta so Food Type is consistent with UI
      final isVeg = m['isVeg'] is bool ? (m['isVeg'] as bool) : null;
      final foodTypeRaw = (m['foodType'] ?? '').toString().trim();
      final food = _foodMeta(isVeg, foodTypeRaw.isEmpty ? null : foodTypeRaw);

      final price = _toDouble(m['price']);

      sheet.appendRow(<ex.CellValue?>[
        t(name.isEmpty ? '—' : name),
        t(category.isEmpty ? 'Other' : category),
        t(food.label.isEmpty ? '—' : food.label),
        t(price == null ? '—' : '\$${price.toStringAsFixed(0)}'),
      ]);

      // ✅ Make "Item" column bold for each row
      sheet
          .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .cellStyle = itemBoldStyle;

      rowIndex++;
    }

    if (excel.sheets.keys.contains('Sheet1') && excel.sheets.keys.length > 1) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final guestName = _safeFileName(_safeName(guest));
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'selected_menu_$guestName.xlsx')
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  void _resetGuestTable() {
    setState(() {
      _guestFirstRowIndex = 0;
    });
  }

  void _clearDietFilter() {
    setState(() {
      _dietFilter = DietFilter.all;
      _resetGuestTable();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _dietFilter = DietFilter.all;
      _menuSearchCtrl.clear();

      _selectedGuest = null;
      _guestSearchCtrl.clear();

      _guestDietType = GuestDietType.all;
      _selectedMenuItemIds.clear();

      _resetGuestTable();
    });
  }

  Widget _buildGuestDietBelowTabs() {
    Widget chip({
      required String text,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        checkmarkColor: Colors.white,
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.black,
        backgroundColor: const Color(0xFFF3F4F6),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Guest diet preference',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              chip(
                text: 'All',
                selected: _guestDietType == GuestDietType.all,
                onTap: () => setState(() {
                  _guestDietType = GuestDietType.all;
                  _resetGuestTable();
                }),
              ),
              chip(
                text: 'Veg',
                selected: _guestDietType == GuestDietType.veg,
                onTap: () => setState(() {
                  _guestDietType = GuestDietType.veg;
                  _resetGuestTable();
                }),
              ),
              chip(
                text: 'Non-Veg',
                selected: _guestDietType == GuestDietType.nonVeg,
                onTap: () => setState(() {
                  _guestDietType = GuestDietType.nonVeg;
                  _resetGuestTable();
                }),
              ),
              chip(
                text: 'Both',
                selected: _guestDietType == GuestDietType.both,
                onTap: () => setState(() {
                  _guestDietType = GuestDietType.both;
                  _resetGuestTable();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Filters (common + guest-only on Guest tab)
  // ─────────────────────────────────────────────
  Widget _buildFilters({
    required List<Map<String, dynamic>> guestSelections,
  }) {
    final isPhone = MediaQuery.sizeOf(context).width < 700;
    Widget chip({
      required String text,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        checkmarkColor: Colors.white,
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.black,
        backgroundColor: const Color(0xFFF3F4F6),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      );
    }

    Widget sectionBox(String title, Widget child) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
    }

    Widget clearAllBox() {
      final anyActive = _dietFilter != DietFilter.all ||
          _menuSearchCtrl.text.trim().isNotEmpty ||
          _selectedGuest != null ||
          _guestSearchCtrl.text.trim().isNotEmpty ||
          _guestDietType != GuestDietType.all ||
          _selectedMenuItemIds.isNotEmpty;

      return sectionBox(
        'Actions',
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: anyActive ? _clearAllFilters : null,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: Text(
              'Clear all filters',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    Widget dietBox() {
      final isActive = _dietFilter != DietFilter.all;

      return sectionBox(
        'Filter by diet',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                chip(
                  text: 'All',
                  selected: _dietFilter == DietFilter.all,
                  onTap: () => setState(() {
                    _dietFilter = DietFilter.all;
                    _resetGuestTable();
                  }),
                ),
                chip(
                  text: 'Veg',
                  selected: _dietFilter == DietFilter.veg,
                  onTap: () => setState(() {
                    _dietFilter = DietFilter.veg;
                    _resetGuestTable();
                  }),
                ),
                chip(
                  text: 'Non-Veg',
                  selected: _dietFilter == DietFilter.nonVeg,
                  onTap: () => setState(() {
                    _dietFilter = DietFilter.nonVeg;
                    _resetGuestTable();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isActive ? _clearDietFilter : null,
                icon: const Icon(Icons.clear, size: 18),
                label: Text(
                  'Clear diet filter',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget menuSearchBox() {
      return sectionBox(
        'Search menu items',
        TextField(
          controller: _menuSearchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search menu item name...',
            hintStyle: GoogleFonts.poppins(),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: _menuSearchCtrl.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () => setState(() => _menuSearchCtrl.clear()),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      );
    }

    Widget guestBox() {
      final q = _guestSearchCtrl.text.trim().toLowerCase();

      final suggestions = (_selectedGuest != null || q.isEmpty)
          ? <Map<String, dynamic>>[]
          : guestSelections.where((g) {
              final name = (g['name'] ?? g['guestName'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              final email = (g['email'] ?? g['guestEmail'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              return name.contains(q) || email.contains(q);
            }).toList();

      if (_selectedGuest != null) {
        return sectionBox(
          'Filter by guest',
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_selectedGuest?['name'] ??
                                  _selectedGuest?['guestName'] ??
                                  '')
                              .toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGuest = null;
                    _guestSearchCtrl.clear();
                    _resetGuestTable();
                  });
                },
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      }

      return sectionBox(
        'Filter by guest',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _guestSearchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search guest name...',
                hintStyle: GoogleFonts.poppins(),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final g = suggestions[i];
                      final name = (g['name'] ??
                              g['guestName'] ??
                              g['email'] ??
                              g['guestEmail'] ??
                              '')
                          .toString();

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline),
                        title: Text(
                          name,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedGuest = g;
                            _guestSearchCtrl.text = name;
                            _resetGuestTable();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final commonBoxes = <Widget>[
      dietBox(),
      menuSearchBox(),
      guestBox(),
      clearAllBox()
    ];

    if (isPhone) {
      final children = <Widget>[];
      for (final b in commonBoxes) {
        children.add(b);
        children.add(const SizedBox(height: 12));
      }
      if (children.isNotEmpty) children.removeLast();
      return Column(children: children);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final maxW = constraints.maxWidth;

        // ✅ fixed-feel cards like a pro dashboard
        final rawW = maxW >= 1200
            ? 360.0
            : maxW >= 900
                ? (maxW - gap) / 2
                : maxW;

        final boxW = rawW.clamp(280.0, 420.0);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            ...commonBoxes.map((b) => SizedBox(width: boxW, child: b)),
          ],
        );
      },
    );
  }

  Widget _buildSegmentedTabs(TabController ctrl) {
    return LayoutBuilder(
      builder: (context, c) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final isNarrow = c.maxWidth < 520;
        final maxW = isNarrow ? c.maxWidth : 520.0;

        // Shell styling (theme-aware)
        final shellBg = isDark ? cs.surface.withOpacity(0.65) : cs.surface;
        final shellBorder = cs.outline.withOpacity(isDark ? 0.45 : 0.22);

        // Selected styling (gradient based on theme)
        final selGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.secondary,
          ],
        );
        final selFg = cs.onPrimary;

        // Unselected styling
        final unselFg = cs.onSurface;
        final unselBg = Colors.transparent;

        Widget seg({
          required int index,
          required String label,
          required IconData icon,
        }) {
          final selected = ctrl.index == index;

          final child = AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? null : unselBg,
              gradient: selected ? selGrad : null,
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
                  color: selected ? selFg : unselFg,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? selFg : unselFg,
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
                      label: "Menu Items",
                      icon: Icons.restaurant_menu),
                  const SizedBox(width: 6),
                  seg(
                      index: 1,
                      label: "Guest List",
                      icon: Icons.people_alt_outlined),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // UI helpers
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

  Widget _imagePlaceholder({bool loading = false}) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_outlined,
                color: Color(0xFF9CA3AF), size: 34),
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
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _dietPill(String label) {
    final norm = label.toLowerCase().replaceAll(' ', '').replaceAll('-', '');

    Color bg;
    Color fg;

    if (norm == 'veg' || norm == 'vegetarian') {
      bg = const Color(0xFF16A34A); // green
      fg = Colors.white;
    } else if (norm == 'nonveg' || norm == 'nonvegetarian') {
      bg = const Color(0xFFDC2626); // red
      fg = Colors.white;
    } else if (norm.contains('both')) {
      bg = const Color(0xFF7C3AED); // purple
      fg = Colors.white;
    } else {
      bg = const Color(0xFF6B7280); // gray
      fg = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _countPill({
    required String label, // e.g. "Veg"
    required int count, // e.g. 3
    required Color bg, // e.g. green/red/purple
  }) {
    final w = MediaQuery.sizeOf(context).width;

    // responsive sizing
    final numFs = w < 900 ? 16.0 : 18.0; // ✅ bigger number
    final labelFs = w < 900 ? 11.0 : 12.0; // ✅ smaller label

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: numFs,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: labelFs,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.95),
              height: 1.0,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Guest table section + table
  // ─────────────────────────────────────────────
  Widget _guestTableSection({
    required List<Map<String, dynamic>> guests,
    required List<Map<String, dynamic>> allMenuItems,
    required String? selectedItemsLabel,
    required int selectedItemsCount,
    required int menuItemCountForTable,
    required List<Map<String, dynamic>> menuItemsForExport,
    required int totalResponses,
  }) {
    final filteredItemIds =
        menuItemsForExport.map(_menuItemId).where((s) => s.isNotEmpty).toSet();

    final allSelected = filteredItemIds.isNotEmpty &&
        _selectedMenuItemIds.length == filteredItemIds.length;

    // ✅ IMPORTANT: dedupe but DON'T merge different names with same email
    final dedupedGuests = _dedupeGuests(guests)
      ..sort((a, b) =>
          _safeName(a).toLowerCase().compareTo(_safeName(b).toLowerCase()));

    final counts = countDiet(dedupedGuests);
    final w = MediaQuery.sizeOf(context).width;
    final headingFs = w < 900 ? 18.0 : 20.0;

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
              _pill('${dedupedGuests.length} guests'),
              if (_selectedMenuItemIds.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selectedItemsLabel ?? '$selectedItemsCount items selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                _pill('From $menuItemCountForTable filtered items'),
              _countPill(
                  label: 'Veg', count: counts.veg, bg: const Color(0xFF16A34A)),
              _countPill(
                  label: 'Non-Veg',
                  count: counts.nonVeg,
                  bg: const Color(0xFFDC2626)),
              if (counts.both > 0)
                _countPill(
                    label: 'Both',
                    count: counts.both,
                    bg: const Color(0xFF7C3AED)),
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
                if (filteredItemIds.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (!allSelected) {
                          _selectedMenuItemIds
                            ..clear()
                            ..addAll(filteredItemIds);
                        }
                      });
                    },
                    child: Text(
                      allSelected ? 'All selected' : 'Select all',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    ),
                  ),
                if (_selectedMenuItemIds.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedMenuItemIds.clear()),
                    child: Text(
                      'Clear items',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    ),
                  ),
                OutlinedButton.icon(
                  style: outlineStyle,
                  onPressed: menuItemsForExport.isEmpty
                      ? null
                      : () => _exportMenuItemsToExcel(
                            menuItemsForExport,
                            totalResponses: totalResponses,
                          ),
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: Text(
                    'Export Menu',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  style: primaryStyle,
                  onPressed: dedupedGuests.isEmpty
                      ? null
                      : () => _exportGuestsMenuMatrixToExcel(
                            dedupedGuests,
                            allMenuItems,
                            fileName: 'guest_menu_matrix.xlsx',
                          ),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(
                    'Export Guests',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMenuItemIds.isNotEmpty
                ? 'Showing guests who selected the selected menu items.'
                : 'Tip: select menu item cards in the Menu tab to focus this table.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (dedupedGuests.isEmpty)
            _emptyHint('No guests match your current filters.')
          else
            _guestDataTable(dedupedGuests, allMenuItems),
        ],
      ),
    );
  }

  Widget _guestDataTable(
    List<Map<String, dynamic>> guests,
    List<Map<String, dynamic>> allMenuItems,
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
        final nameW = (tableW * 0.26).clamp(170.0, 320.0);
        final emailW = (tableW * 0.46).clamp(240.0, 560.0);
        final dietW = (tableW - nameW - emailW - actionW).clamp(200.0, 280.0);

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

        final src = _GuestDataSource(
          guests: guests,
          nameOf: _safeName,
          emailOf: _safeEmail,
          dietWidgetOf: (g) => _dietPill(_guestDietExcelLabel(g)),
          downloadActionOf: (g) {
            final ids = _asStringSet(g['selectedMenuItemIds']);
            if (ids.isEmpty) return null;
            return () => _exportSelectedMenuForGuest(
                  guest: g,
                  allMenuItems: allMenuItems,
                );
          },
          cellStyle: cellStyle,
          headStyle: headStyle,
          nameW: nameW,
          emailW: emailW,
          dietW: dietW,
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
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF3F4F6),
                ),
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
                  DataColumn(label: headCell('Diet', dietW)),
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

  Widget _menuCard({
    required double cardW,
    required double imageH,
    required bool selected,
    required VoidCallback? onTap,
    required String name,
    required String category,
    required bool? isVeg,
    required String? foodType,
    required double? price,
    required String? imageUrl,
    required int count,
    required int percent, // (unused now, kept to avoid refactor)
    required VoidCallback? onDownloadGuests,
  }) {
    final food = _foodMeta(isVeg, foodType);

    // Slight scaling for narrow cards (5-col)
    final titleFs = cardW < 240
        ? 14.5
        : cardW < 280
            ? 16.0
            : 17.5;
    final catFs = cardW < 240 ? 12.0 : 13.0;
    final guestsFs = cardW < 240 ? 13.0 : 14.5;

    final priceText = price != null ? '\$${price.toStringAsFixed(0)}' : '—';
    final downloadEnabled = onDownloadGuests != null;

    final screenW = MediaQuery.sizeOf(context).width;
    final enableHoverTooltip = screenW >= 1100; // desktop only
    final titleMaxLines = enableHoverTooltip ? 1 : 2;

    final titleWidget = Text(
      name,
      maxLines: titleMaxLines,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: titleFs,
        fontWeight: FontWeight.w900,
        height: 1.15,
        color: const Color(0xFF111827),
      ),
    );

    final title = enableHoverTooltip
        ? _HoverTooltip(message: name, enabled: true, child: titleWidget)
        : titleWidget;

    // Premium hover effect (web/desktop) – keeps your current “selected lift”
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 160),
      builder: (context, t, child) {
        return MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, t * -1.5, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? Colors.black : const Color(0xFFE5E7EB),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(selected ? 0.08 : 0.05),
                  blurRadius: selected ? 18 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Image header
                      SizedBox(
                        height: imageH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : _imagePlaceholder(loading: true),
                              )
                            else
                              _imagePlaceholder(),

                            // subtle gradient for readability
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.04),
                                      Colors.black.withOpacity(0.18),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ✅ add/check button (top-right)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.14),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  selected ? Icons.check : Icons.add,
                                  size: 22,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Diet mark + title in one straight line
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _dietMark(food),
                                const SizedBox(width: 10),
                                Expanded(child: title),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // ✅ Category + Price chip row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.isEmpty ? 'Other' : category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: catFs,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFEEF2FF),
                                        Color(0xFFE0E7FF)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: Text(
                                    priceText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ✅ Guests + download button (no % now)
                            Row(
                              children: [
                                const Icon(Icons.people_alt_outlined,
                                    size: 18, color: Color(0xFF111827)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$count',
                                          style: GoogleFonts.poppins(
                                            fontSize: guestsFs +
                                                2.5, // ✅ bigger number
                                            fontWeight: FontWeight
                                                .w900, // ✅ bold number
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' guests',
                                          style: GoogleFonts.poppins(
                                            fontSize: guestsFs, // ✅ normal size
                                            fontWeight:
                                                FontWeight.w500, // ✅ not bold
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ✅ Use HoverTooltip (desktop only) instead of Tooltip
                                _HoverTooltip(
                                  message: downloadEnabled
                                      ? 'Download guests for this item'
                                      : 'No guests to download',
                                  enabled: enableHoverTooltip,
                                  child: InkWell(
                                    onTap: downloadEnabled
                                        ? onDownloadGuests
                                        : null,
                                    borderRadius: BorderRadius.circular(14),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: downloadEnabled
                                            ? const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF2563EB),
                                                  Color(0xFF1D4ED8),
                                                ],
                                              )
                                            : const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFFE5E7EB),
                                                  Color(0xFFD1D5DB),
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: downloadEnabled
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF2563EB)
                                                      .withOpacity(0.25),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Icon(
                                        Icons.file_download_outlined,
                                        size: 22,
                                        color: downloadEnabled
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dietMark(FoodMeta food) {
    // veg => green, non-veg => red, other => grey
    final dot = food.label == 'Veg'
        ? Colors.green.shade700
        : food.label == 'Non-Veg'
            ? Colors.red.shade700
            : Colors.grey.shade600;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build (tabs + content)
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final menu = _asMap(_data?['menu']);
    final menuResponses = _toInt(menu['responses']);

    final items = _asMapList(menu['items'])
      ..sort((a, b) => _toInt(b['count']) - _toInt(a['count']));

    final guestSelections = _asGuestSelections(menu['guestSelections']);

    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

    const int limit = 12;

    final selectedIds = _selectedGuest == null
        ? null
        : _asStringSet(_selectedGuest?['selectedMenuItemIds']);

    final mq = _menuSearchCtrl.text.trim().toLowerCase();

    final filteredItems = items.where((m) {
      if (mq.isNotEmpty) {
        final n = (m['name'] ?? '').toString().trim().toLowerCase();
        final cat = (m['categoryLabel'] ?? m['category'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (!n.contains(mq) && !cat.contains(mq)) return false;
      }

      if (selectedIds != null) {
        final id = _menuItemId(m);
        if (id.isEmpty) return false;
        if (!selectedIds.contains(id)) return false;
      }

      if (!_matchesDiet(m)) return false;
      return true;
    }).toList();

    final filteredItemIds = filteredItems
        .map((m) => (m['id'] ?? m['menuItemId'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final activeMenuItemIds = _selectedMenuItemIds.isEmpty
        ? filteredItemIds
        : _selectedMenuItemIds.intersection(filteredItemIds);

    final selectedGuestKey =
        _selectedGuest == null ? null : _guestKey(_selectedGuest!);

    final filteredGuests = guestSelections.where((g) {
      if (!_matchesGuestDiet(g)) return false;

      if (selectedGuestKey != null && _guestKey(g) != selectedGuestKey)
        return false;

      if (activeMenuItemIds.isEmpty) return false;
      final ids = _asStringSet(g['selectedMenuItemIds']);
      return ids.any(activeMenuItemIds.contains);
    }).toList()
      ..sort((a, b) =>
          _safeName(a).toLowerCase().compareTo(_safeName(b).toLowerCase()));

    String? selectedItemsLabel;
    if (_selectedMenuItemIds.isNotEmpty) {
      final names = items
          .where((m) => _selectedMenuItemIds.contains(_menuItemId(m)))
          .map((m) => (m['name'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (names.isEmpty) {
        selectedItemsLabel = '${_selectedMenuItemIds.length} items selected';
      } else if (_selectedMenuItemIds.length <= 2) {
        selectedItemsLabel = names.take(2).join(', ');
      } else {
        selectedItemsLabel = '${_selectedMenuItemIds.length} items selected';
      }
    }

    final shownCount = _showAll
        ? filteredItems.length
        : (filteredItems.length > limit ? limit : filteredItems.length);

    final tabCtrl = _tabCtrl; // local
    final isMenuTab = (_tabCtrl?.index ?? 0) == 0;
    final isGuestTab = (_tabCtrl?.index ?? 0) == 1;

    final screenW = MediaQuery.sizeOf(context).width;

    final hPad = screenW >= 1200 ? 28.0 : 16.0;

    return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 40),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: Container(
              // ✅ keep your existing container style here
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
                  // header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu analyzer',
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

                  const SizedBox(height: 18),

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
                      'Failed to load',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text('Try again', style: GoogleFonts.poppins()),
                    ),
                  ] else if (menuResponses == 0 || items.isEmpty) ...[
                    _emptyHint('No menu selections yet.'),
                  ] else ...[
                    _buildFilters(guestSelections: guestSelections),

                    const SizedBox(height: 16),

                    // Tabs
                    if (tabCtrl != null) _buildSegmentedTabs(tabCtrl),

                    const SizedBox(height: 16),

                    if (isGuestTab) ...[
                      _buildGuestDietBelowTabs(),
                      const SizedBox(height: 16),
                    ],

                    if (isMenuTab) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Menu item responses',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$menuResponses responses',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: const Color(0xFF6B7280)),
                          ),
                          if (_selectedGuest != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                'Guest: ${(_selectedGuest?['name'] ?? _selectedGuest?['guestName'] ?? '').toString()}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                          if (filteredItems.length > limit)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showAll = !_showAll),
                              child: Text(
                                _showAll ? 'Show top $limit' : 'Show all',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filteredItems.isEmpty)
                        _emptyHint('No items match your filters.')
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;

                            int cols;
                            if (w < 520)
                              cols = 2;
                            else if (w < 760)
                              cols = 3;
                            else if (w < 1100)
                              cols = 4;
                            else
                              cols = 5;

                            const cross = 16.0;
                            const main = 16.0;

                            final cardW = (w - (cols - 1) * cross) / cols;

                            final imageH = (cardW * 0.48).clamp(120.0, 160.0);

                            final contentH = cardW < 250
                                ? 170.0
                                : cardW < 290
                                    ? 160.0
                                    : 150.0;

                            final cardH = imageH + contentH + 10;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _showAll ? filteredItems.length : shownCount,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: cross,
                                mainAxisSpacing: main,
                                mainAxisExtent:
                                    cardH, // ✅ now it scales correctly
                              ),
                              itemBuilder: (_, idx) {
                                final m = filteredItems[idx];

                                final name =
                                    (m['name'] ?? 'Menu item').toString();
                                final category = _prettyCategory(
                                  (m['categoryLabel'] ?? m['category'] ?? '')
                                      .toString(),
                                );

                                final isVeg = m['isVeg'] is bool
                                    ? (m['isVeg'] as bool)
                                    : null;
                                final foodType =
                                    (m['foodType'] ?? '').toString().trim();
                                final price = _toDouble(m['price']);
                                final imageUrl =
                                    (m['imageUrl'] ?? '').toString().trim();

                                final count = _toInt(m['count']);
                                final pct = menuResponses <= 0
                                    ? 0
                                    : ((count / menuResponses) * 100).round();

                                final itemId =
                                    (m['id'] ?? m['menuItemId'] ?? '')
                                        .toString()
                                        .trim();
                                final guestsForThisItem =
                                    _guestsForMenuItem(itemId, guestSelections);
                                final file =
                                    'guests_${_safeFileName(name)}.xlsx';

                                return _menuCard(
                                  cardW: cardW,
                                  imageH: imageH,
                                  selected: itemId.isNotEmpty &&
                                      _selectedMenuItemIds.contains(itemId),
                                  onTap: itemId.isEmpty
                                      ? null
                                      : () {
                                          setState(() {
                                            if (_selectedMenuItemIds
                                                .contains(itemId)) {
                                              _selectedMenuItemIds
                                                  .remove(itemId);
                                            } else {
                                              _selectedMenuItemIds.add(itemId);
                                            }
                                            _resetGuestTable(); // ✅ if you added the table reset earlier
                                          });
                                        },
                                  name: name,
                                  category: category,
                                  isVeg: isVeg,
                                  foodType: foodType.isEmpty ? null : foodType,
                                  price: price,
                                  imageUrl: imageUrl.isEmpty ? null : imageUrl,
                                  count: count,
                                  percent: pct,
                                  onDownloadGuests: guestsForThisItem.isEmpty
                                      ? null
                                      : () => _exportGuestsToExcel(
                                          guestsForThisItem,
                                          fileName: file),
                                );
                              },
                            );
                          },
                        ),
                    ],

                    if (isGuestTab) ...[
                      _guestTableSection(
                        guests: filteredGuests,
                        allMenuItems: items,
                        selectedItemsLabel: selectedItemsLabel,
                        selectedItemsCount: _selectedMenuItemIds.length,
                        menuItemCountForTable: activeMenuItemIds.length,
                        menuItemsForExport: filteredItems,
                        totalResponses: menuResponses,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ));
  }
}

class _HoverTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final bool enabled;

  const _HoverTooltip({
    required this.message,
    required this.child,
    required this.enabled,
  });

  @override
  State<_HoverTooltip> createState() => _HoverTooltipState();
}

class _HoverTooltipState extends State<_HoverTooltip> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  void _show() {
    if (!widget.enabled || _entry != null) return;

    _entry = OverlayEntry(
      builder: (context) {
        // ✅ Fill overlay but keep tooltip bubble unconstrained
        return Positioned.fill(
          child: IgnorePointer(
            child: UnconstrainedBox(
              alignment: Alignment.topLeft,
              child: CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                offset: const Offset(0, -8),
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: widget.child,
      ),
    );
  }
}

class DietCounts {
  final int veg;
  final int nonVeg;
  final int both;
  final int unknown;
  const DietCounts(
      {required this.veg,
      required this.nonVeg,
      required this.both,
      required this.unknown});
}
