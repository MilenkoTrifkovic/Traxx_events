import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';

// ✅ record-free
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

GuestDietType _guestDietType = GuestDietType.all;

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

  // ✅ Filters
  DietFilter _dietFilter = DietFilter.all;

  final TextEditingController _guestSearchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedGuest; // {name, selectedMenuItemIds}
  bool _matchesGuestDiet(Map<String, dynamic> g) {
    if (_guestDietType == GuestDietType.all) return true;

    final dt = (g['dietType'] ?? '').toString().trim().toLowerCase();

    if (_guestDietType == GuestDietType.veg) return dt == 'veg';
    if (_guestDietType == GuestDietType.nonVeg) return dt == 'nonveg';
    if (_guestDietType == GuestDietType.both) return dt == 'both';

    return true;
  }

  @override
  void initState() {
    super.initState();
    _svc = Get.find<CloudFunctionsService>();
    _load();
  }

  @override
  void dispose() {
    _guestSearchCtrl.dispose();
    super.dispose();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
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
    // Accept either {name} or {guestName} (and email fallbacks)
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

  Widget _buildFilters({
    required List<Map<String, dynamic>> guestSelections,
  }) {
    final isPhone = MediaQuery.sizeOf(context).width < 700;

    final q = _guestSearchCtrl.text.trim().toLowerCase();

    final suggestions = (_selectedGuest != null || q.isEmpty)
        ? <Map<String, dynamic>>[]
        : guestSelections.where((g) {
            if (!_matchesGuestDiet(g)) return false;

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

    Widget dietBox() {
      Widget chip(String text, bool selected, VoidCallback onTap) {
        return ChoiceChip(
          checkmarkColor: Colors.white,
          label: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: Colors.black,
          backgroundColor: const Color(0xFFF3F4F6),
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
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
              'Filter by diet',
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
                ChoiceChip(
                  label: const Text('All'),
                  selected: _guestDietType == GuestDietType.all,
                  onSelected: (_) =>
                      setState(() => _guestDietType = GuestDietType.all),
                ),
                ChoiceChip(
                  label: const Text('Veg'),
                  selected: _guestDietType == GuestDietType.veg,
                  onSelected: (_) =>
                      setState(() => _guestDietType = GuestDietType.veg),
                ),
                ChoiceChip(
                  label: const Text('Non-Veg'),
                  selected: _guestDietType == GuestDietType.nonVeg,
                  onSelected: (_) =>
                      setState(() => _guestDietType = GuestDietType.nonVeg),
                ),
                ChoiceChip(
                  label: const Text('Both'),
                  selected: _guestDietType == GuestDietType.both,
                  onSelected: (_) =>
                      setState(() => _guestDietType = GuestDietType.both),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    Widget guestBox() {
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
              'Filter by guest',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            // Selected guest chip
            if (_selectedGuest != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
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
                      });
                    },
                    child: Text('Clear',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ] else ...[
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

              // Suggestions list (inline, no overlay)
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
                          title: Text(name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700)),
                          onTap: () {
                            setState(() {
                              _selectedGuest = g;
                              _guestSearchCtrl.text = name;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],

              if (_guestSearchCtrl.text.trim().isNotEmpty &&
                  suggestions.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'No guests match your search.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    }

    if (isPhone) {
      return Column(
        children: [
          dietBox(),
          const SizedBox(height: 12),
          guestBox(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: dietBox()),
        const SizedBox(width: 14),
        Expanded(child: guestBox()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = _asMap(_data?['menu']);
    final menuResponses = _toInt(menu['responses']);

    final items = _asMapList(menu['items'])
      ..sort((a, b) => _toInt(b['count']) - _toInt(a['count']));

    // ✅ guestSelections must come from Cloud Function: menu.guestSelections
    final guestSelections = _asGuestSelections(menu['guestSelections']);

    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

    const int limit = 12;

    // ✅ Apply filters
    final selectedIds = _selectedGuest == null
        ? null
        : _asStringSet(
            _selectedGuest?['selectedMenuItemIds'] ??
                _selectedGuest?['selectedMenuItemIds'],
          );

    final filteredItems = items.where((m) {
      if (!_matchesDiet(m)) return false;

      if (selectedIds != null) {
        final id = (m['id'] ?? m['menuItemId'] ?? '').toString().trim();
        if (id.isEmpty) return false;
        if (!selectedIds.contains(id)) return false;
      }
      return true;
    }).toList();

    final shownCount = _showAll
        ? filteredItems.length
        : (filteredItems.length > limit ? limit : filteredItems.length);

    return TooltipVisibility(
      visible: false,
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
              // header
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
                          'Menu items analyzer',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
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
                // ✅ FILTER SECTION (split into 2)
                _buildFilters(guestSelections: guestSelections),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Menu item responses',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$menuResponses responses',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (_selectedGuest != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Guest: ${(_selectedGuest?['name'] ?? '').toString()}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    if (filteredItems.length > limit)
                      TextButton(
                        onPressed: () => setState(() => _showAll = !_showAll),
                        child: Text(
                          _showAll ? 'Show top $limit' : 'Show all',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: shownCount,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent:
                              400, // ✅ more space (prevents overflow)
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemBuilder: (_, idx) {
                          final m = filteredItems[idx];

                          final name = (m['name'] ?? 'Menu item').toString();
                          final category = _prettyCategory(
                            (m['categoryLabel'] ?? m['category'] ?? '')
                                .toString(),
                          );
                          final description =
                              (m['description'] ?? '').toString().trim();

                          final isVeg =
                              m['isVeg'] is bool ? (m['isVeg'] as bool) : null;
                          final foodType =
                              (m['foodType'] ?? '').toString().trim();

                          final price = _toDouble(m['price']);
                          final imageUrl =
                              (m['imageUrl'] ?? '').toString().trim();

                          final count = _toInt(m['count']);
                          final pct = menuResponses <= 0
                              ? 0
                              : ((count / menuResponses) * 100).round();

                          return _menuCard(
                            name: name,
                            category: category,
                            description: description,
                            isVeg: isVeg,
                            foodType: foodType.isEmpty ? null : foodType,
                            price: price,
                            imageUrl: imageUrl.isEmpty ? null : imageUrl,
                            count: count,
                            percent: pct,
                            totalResponses: menuResponses,
                          );
                        },
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

  Widget _menuCard({
    required String name,
    required String category,
    required String description,
    required bool? isVeg,
    required String? foodType,
    required double? price,
    required String? imageUrl,
    required int count,
    required int percent,
    required int totalResponses,
  }) {
    final food = _foodMeta(isVeg, foodType);
    final progress =
        totalResponses <= 0 ? 0.0 : (count / totalResponses).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ IMAGE (slightly smaller)
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _imagePlaceholder(loading: true);
                      },
                    )
                  else
                    _imagePlaceholder(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ DETAILS (no Expanded; prevents overflow)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Category below name using _detailRow
                  _detailRow(
                    icon: Icons.category_outlined,
                    iconColor: const Color(0xFF111827),
                    label: 'Category',
                    value: category.isEmpty ? 'Other' : category,
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: food.icon,
                    iconColor: food.color,
                    label: 'Food type',
                    value: food.label,
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: Icons.attach_money_outlined,
                    iconColor: const Color(0xFF111827),
                    label: 'Price',
                    value:
                        price == null ? '—' : '\$${price!.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: Icons.bar_chart_outlined,
                    iconColor: const Color(0xFF111827),
                    label: 'Selected by',
                    value: '$count guests ($percent%)',
                  ),
                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 8,
                      color: const Color(0xFFE5E7EB),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                  fontSize: 15, color: const Color(0xFF111827)),
              children: [
                TextSpan(
                  text: '$label:  ',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
}
