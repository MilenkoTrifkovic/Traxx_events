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

  @override
  void initState() {
    super.initState();
    _load();
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

      final items = (res['items'] as List?) ?? const [];
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
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? Center(
                child: Text(
                  'No menu items available for this event.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final it = _items[i];
                  final checked = _selected.contains(it.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: kBorder),
                      ),
                      child: ListTile(
                        title: Text(it.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, color: kTextDark)),
                        subtitle: it.description.isEmpty
                            ? null
                            : Text(it.description,
                                style: GoogleFonts.poppins(color: kTextBody)),
                        trailing: Checkbox(
                          value: checked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(it.id);
                              } else {
                                _selected.remove(it.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
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

  _MenuItemDto(
      {required this.id, required this.name, required this.description});

  factory _MenuItemDto.fromMap(Map<String, dynamic> m) {
    return _MenuItemDto(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Menu item').toString(),
      description: (m['description'] ?? '').toString(),
    );
  }
}
