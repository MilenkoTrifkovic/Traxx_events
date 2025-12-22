import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart'; // adjust import

const Color kGfPurple = Color(0xFF673AB7);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color gfBackground = Color(0xFFF4F0FB);

class GuestMenuSelectionPage extends StatefulWidget {
  final String invitationId;
  const GuestMenuSelectionPage({super.key, required this.invitationId});

  @override
  State<GuestMenuSelectionPage> createState() => _GuestMenuSelectionPageState();
}

class _GuestMenuSelectionPageState extends State<GuestMenuSelectionPage> {
  bool _loading = true;
  bool _submitting = false;

  String _eventName = 'Menu Selection';
  List<_MenuItemDto> _items = [];
  final Set<String> _selected = {};

  String get _token => (Uri.base.queryParameters['token'] ?? '').trim();
  String _search = '';
  bool? _vegFilter; // null=all, true=veg, false=non-veg

  List<_MenuItemDto> get _filteredItems {
    var list = [..._items];

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((it) {
        return it.name.toLowerCase().contains(q) ||
            it.description.toLowerCase().contains(q);
      }).toList();
    }

    if (_vegFilter != null) {
      list = list.where((it) => it.isVeg == _vegFilter).toList();
    }

    return list;
  }

  int get _vegCount => _items.where((x) => x.isVeg == true).length;
  int get _nonVegCount => _items.where((x) => x.isVeg == false).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.black : kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = _token;
      if (token.isEmpty) throw Exception('Missing token');
      final inv = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(widget.invitationId)
          .get();

      final invData = inv.data();
      if (invData != null && invData['menuSelectionSubmitted'] == true) {
        if (!mounted) return;
        context.go(
            '/thank-you?invitationId=${Uri.encodeComponent(widget.invitationId)}');
        return;
      }

      final cf = Get.find<CloudFunctionsService>();
      final res = await cf.getSelectedMenuItemsForInvitation(
        invitationId: widget.invitationId,
        token: token,
      );
      print(
          'CF getSelectedMenuItemsForInvitation res keys: ${res.keys.toList()}');
      final items = (res['items'] as List?) ?? const [];
      print('CF items length: ${items.length}');
      if (items.isNotEmpty) {
        print('CF first item raw: ${items.first}');
      }
      final eventName = (res['eventName'] ?? 'Menu Selection').toString();

      setState(() {
        _eventName = eventName;
        _items = items
            .map((x) =>
                _MenuItemDto.fromMap(Map<String, dynamic>.from(x as Map)))
            .toList();
      });
    } catch (e) {
      setState(() {
        _items = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load menu items: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final token = _token;
      if (token.isEmpty) throw Exception('Missing token');

      final cf = Get.find<CloudFunctionsService>();
      await cf.submitMenuSelection(
        invitationId: widget.invitationId,
        token: token,
        selectedMenuItemIds: _selected.toList(),
      );

      if (!mounted) return;

      // ✅ go to thank-you (no back)
      context.go(
        '/thank-you?invitationId=${Uri.encodeComponent(widget.invitationId)}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? Center(
                child: Text(
                  'No menu items available for this event.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              )
            : Column(
                children: [
                  // Search + filters (like popup)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: kBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) => setState(() => _search = v),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search dish name, e.g. "rice"',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: kBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: kBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _filterChip(
                                label: 'All (${_items.length})',
                                selected: _vegFilter == null,
                                onTap: () => setState(() => _vegFilter = null),
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                label: 'Veg ($_vegCount)',
                                selected: _vegFilter == true,
                                onTap: () => setState(() => _vegFilter = true),
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                label: 'Non-Veg ($_nonVegCount)',
                                selected: _vegFilter == false,
                                onTap: () => setState(() => _vegFilter = false),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() {
                                  _search = '';
                                  _vegFilter = null;
                                }),
                                child: Text('Clear',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final it = list[i];
                        final selected = _selected.contains(it.id);

                        final Color tint = it.isVeg == true
                            ? Colors.green.shade50
                            : it.isVeg == false
                                ? Colors.red.shade50
                                : Colors.grey.shade50;

                        final Color border = it.isVeg == true
                            ? Colors.green.shade400
                            : it.isVeg == false
                                ? Colors.red.shade400
                                : kBorder;

                        final foodTypeLabel = it.isVeg == true
                            ? 'Veg'
                            : it.isVeg == false
                                ? 'Non-Veg'
                                : (it.foodType ?? '');

                        final subtitle = foodTypeLabel.isEmpty
                            ? it.categoryLabel
                            : '$foodTypeLabel • ${it.categoryLabel}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: selected ? tint : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? border : kBorder,
                                width: selected ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Row(
                                children: [
                                  _FoodTypeIcon(isVeg: it.isVeg),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            color: kTextDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        if (it.description
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            it.description,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.8,
                                              fontWeight: FontWeight.w500,
                                              color: kTextBody,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: 34,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              if (selected) {
                                                _selected.remove(it.id);
                                              } else {
                                                _selected.add(it.id);
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: selected
                                                ? Colors.black
                                                : Colors.white,
                                            foregroundColor: selected
                                                ? Colors.white
                                                : Colors.black,
                                            elevation: 0,
                                            side: BorderSide(
                                              color: selected
                                                  ? Colors.black
                                                  : kBorder,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            selected ? 'Remove' : 'Add',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // bottom summary like popup
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _summaryPill('Items', _selected.length.toString()),
                    ],
                  ),
                ],
              );

    return Scaffold(
      backgroundColor: gfBackground,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Menu Selection',
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Card(
                        color: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 6,
                              decoration: const BoxDecoration(
                                color: kGfPurple,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12)),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 18, 24, 22),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _eventName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: kTextDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Select the items you want.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: kTextBody,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: _loading || _submitting
                                          ? null
                                          : _finish,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kGfPurple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: Text('Finish',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Scrollbar(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_submitting)
            Positioned.fill(
              child: Container(
                color: gfBackground.withOpacity(0.35),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItemDto {
  final String id;
  final String name;
  final String description;

  final String categoryLabel;
  final bool? isVeg; // derived
  final String? foodType; // raw (veg/non-veg)
  final double? price;

  _MenuItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryLabel,
    required this.isVeg,
    required this.foodType,
    required this.price,
  });

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static bool? _deriveIsVegFromFoodType(String? ft) {
    final s = (ft ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'veg' || s == 'vegetarian') return true;
    if (s == 'non-veg' || s == 'nonveg' || s == 'non vegetarian') return false;
    if (s.contains('non')) return false;
    return null;
  }

  static String _prettyCategory(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 'Other';

    final lower = s.toLowerCase();

    // Fix common old values
    if (lower == 'dessert') return 'Desserts';
    if (lower == 'entree') return 'Entrees';
    if (lower == 'appetizer') return 'Appetizers';
    if (lower == 'drink') return 'Beverages';

    // Already plural lowercase
    if (lower == 'desserts') return 'Desserts';
    if (lower == 'entrees') return 'Entrees';

    // CamelCase enum keys (foodStations -> Food Stations)
    final spaced =
        s.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').trim();
    final title = spaced.split(' ').where((w) => w.isNotEmpty).map((w) {
      final t = w.toLowerCase();
      if (t == 'bbq') return 'BBQ';
      return t[0].toUpperCase() + t.substring(1);
    }).join(' ');

    // Special labels
    if (s == 'lateNightSnacks') return 'Late-Night Snacks';
    if (s == 'kidsMenu') return 'Kids Menu';
    if (s == 'culturalRegional') return 'Cultural / Regional';
    if (s == 'dietSpecific') return 'Diet-Specific';

    return title;
  }

  factory _MenuItemDto.fromMap(Map<String, dynamic> m) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final rawFoodType = (m['foodType'] ?? '').toString();
    final parsedIsVeg = _parseBool(m['isVeg']);
    final derivedIsVeg = parsedIsVeg ?? _deriveIsVegFromFoodType(rawFoodType);

    final labelFromCf = (m['categoryLabel'] ?? '').toString().trim();
    final rawCategory = (m['categoryKey'] ?? m['category'] ?? '').toString();

    return _MenuItemDto(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Menu item').toString(),
      description: (m['description'] ?? '').toString(),
      categoryLabel:
          labelFromCf.isNotEmpty ? labelFromCf : _prettyCategory(rawCategory),
      isVeg: derivedIsVeg,
      foodType: rawFoodType.trim().isEmpty ? null : rawFoodType.trim(),
      price: asDouble(m['price']),
    );
  }
}

class _FoodTypeIcon extends StatelessWidget {
  final bool? isVeg;
  const _FoodTypeIcon({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final Color c = isVeg == true
        ? Colors.green.shade600
        : isVeg == false
            ? Colors.red.shade600
            : Colors.grey.shade500;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c, width: 2),
        color: c.withOpacity(0.12),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
      ),
    );
  }
}
