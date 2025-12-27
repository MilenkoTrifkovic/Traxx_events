import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

const Color kGfPurple = Color(0xFF673AB7);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color gfBackground = Color(0xFFF4F0FB);

class GuestMenuSelectionPage extends StatefulWidget {
  final String invitationId;
  
  /// Companion index: null = main guest, 0+ = companion
  final int? companionIndex;
  
  /// Display name for companion (optional, for UI)
  final String? companionName;
  
  const GuestMenuSelectionPage({
    super.key, 
    required this.invitationId,
    this.companionIndex,
    this.companionName,
  });

  @override
  State<GuestMenuSelectionPage> createState() => _GuestMenuSelectionPageState();
}

class _GuestMenuSelectionPageState extends State<GuestMenuSelectionPage> {
  bool _loading = true;
  bool _submitting = false;

  String _eventName = 'Menu Selection';
  List<_MenuItemDto> _items = [];
  final Set<String> _selected = {};
  
  Map<String, dynamic>? _invitation;
  
  /// Current companion index (null = main guest, 0+ = companion)
  int? _companionIndex;
  
  /// Display name for current person
  String _currentPersonName = '';
  
  /// Flow state for navigation
  ResponseFlowState? _flowState;

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
    // Initialize companion index from widget or URL
    _companionIndex = widget.companionIndex ?? _readCompanionIndexFromUrl();
    _load();
  }

  @override
  void didUpdateWidget(covariant GuestMenuSelectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if companion index changed (navigation to same page with different params)
    final newCompanionIndex = widget.companionIndex ?? _readCompanionIndexFromUrl();
    final oldCompanionIndex = _companionIndex;
    
    debugPrint('Menu didUpdateWidget: old companionIndex=$oldCompanionIndex, new=$newCompanionIndex');
    
    if (newCompanionIndex != oldCompanionIndex || 
        widget.invitationId != oldWidget.invitationId) {
      debugPrint('*** Menu: Companion index or invitation changed, reloading...');
      _companionIndex = newCompanionIndex;
      _selected.clear(); // Clear previous selections
      _load();
    }
  }

  /// Read companion index from URL query parameters
  int? _readCompanionIndexFromUrl() {
    final idx = Uri.base.queryParameters['companionIndex'];
    if (idx != null && idx.isNotEmpty) {
      return int.tryParse(idx);
    }

    // Hash route support
    final frag = Uri.base.fragment;
    final qIndex = frag.indexOf('?');
    if (qIndex >= 0 && qIndex + 1 < frag.length) {
      final queryPart = frag.substring(qIndex + 1);
      try {
        final params = Uri.splitQueryString(queryPart);
        final compIdx = params['companionIndex'];
        if (compIdx != null && compIdx.isNotEmpty) {
          return int.tryParse(compIdx);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Check if current person (main or companion) has already submitted menu
  bool get _isCurrentPersonDone {
    if (_invitation == null) return false;
    
    if (_companionIndex == null) {
      // Main guest
      return _invitation?['menuSelectionSubmitted'] == true;
    } else {
      // Companion
      final companions = (_invitation?['companions'] as List?) ?? [];
      if (_companionIndex! >= companions.length) return false;
      final companion = companions[_companionIndex!] as Map<String, dynamic>?;
      return companion?['menuSubmitted'] == true;
    }
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

      if (!inv.exists) {
        throw Exception('Invitation not found');
      }

      _invitation = inv.data();
      
      // Build flow state
      _flowState = ResponseFlowState.fromInvitation(
        _invitation!, 
        token,
        invitationIdOverride: widget.invitationId,
      );
      
      // Get companions list
      final companions = (_invitation?['companions'] as List?) ?? [];
      
      // Validate and set current person name
      if (_companionIndex != null) {
        if (_companionIndex! < 0 || _companionIndex! >= companions.length) {
          throw Exception('Invalid companion index');
        }
        final companion = companions[_companionIndex!] as Map<String, dynamic>;
        _currentPersonName = (companion['name'] ?? 'Companion ${_companionIndex! + 1}').toString();
        
        // Check if companion already submitted menu
        if (companion['menuSubmitted'] == true) {
          if (!mounted) return;
          // Navigate to next step using proper method
          _navigateToNextStep();
          return;
        }
        
        // Check if companion has completed demographics first
        if (companion['demographicSubmitted'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demographics must be completed first')),
          );
          // Redirect to demographics for this companion
          context.go(
            '/demographics?invitationId=${Uri.encodeComponent(widget.invitationId)}'
            '&token=${Uri.encodeComponent(token)}'
            '&companionIndex=$_companionIndex',
          );
          return;
        }
      } else {
        // Main guest
        _currentPersonName = (_invitation?['guestName'] ?? 'Guest').toString();
        
        // Check if main guest already submitted menu
        if (_invitation?['menuSelectionSubmitted'] == true) {
          if (!mounted) return;
          _navigateToNextStep();
          return;
        }
        
        // Check if main guest has completed demographics first
        if (_invitation?['used'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demographics must be completed first')),
          );
          context.go(
            '/demographics?invitationId=${Uri.encodeComponent(widget.invitationId)}'
            '&token=${Uri.encodeComponent(token)}',
          );
          return;
        }
      }
      
      // Check if entire flow is complete
      if (_flowState!.isComplete) {
        if (!mounted) return;
        context.go('/thank-you?invitationId=${Uri.encodeComponent(widget.invitationId)}');
        return;
      }

      final cf = Get.find<CloudFunctionsService>();
      final res = await cf.getSelectedMenuItemsForInvitation(
        invitationId: widget.invitationId,
        token: token,
      );
      print('CF getSelectedMenuItemsForInvitation res keys: ${res.keys.toList()}');
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
    
    // If already submitted, navigate to next step
    if (_isCurrentPersonDone) {
      _navigateToNextStep();
      return;
    }
    
    setState(() => _submitting = true);

    try {
      final token = _token;
      if (token.isEmpty) throw Exception('Missing token');

      final cf = Get.find<CloudFunctionsService>();
      await cf.submitMenuSelection(
        invitationId: widget.invitationId,
        token: token,
        selectedMenuItemIds: _selected.toList(),
        companionIndex: _companionIndex, // ✅ Pass companion index
      );

      // Update local state
      Map<String, dynamic> updatedInvitation;
      if (_companionIndex == null) {
        updatedInvitation = Map<String, dynamic>.from(_invitation ?? {});
        updatedInvitation['menuSelectionSubmitted'] = true;
        _invitation = updatedInvitation;
        debugPrint('Menu: Updated local state - menuSelectionSubmitted=${_invitation?['menuSelectionSubmitted']}');
        debugPrint('Menu: Full invitation keys: ${_invitation?.keys.toList()}');
      } else {
        updatedInvitation = Map<String, dynamic>.from(_invitation ?? {});
        final companions = List<Map<String, dynamic>>.from(
          (updatedInvitation['companions'] as List? ?? []).map((c) => Map<String, dynamic>.from(c as Map)),
        );
        if (_companionIndex! < companions.length) {
          companions[_companionIndex!]['menuSubmitted'] = true;
          updatedInvitation['companions'] = companions;
          _invitation = updatedInvitation;
          debugPrint('Menu: Updated companion $_companionIndex menuSubmitted=true');
        }
      }
      
      // Force UI update
      setState(() {});

      // Rebuild flow state with updated invitation - use the same variable we just modified
      debugPrint('Menu: Before creating flow state, _invitation[menuSelectionSubmitted]=${_invitation?['menuSelectionSubmitted']}');
      
      final updatedFlowState = ResponseFlowState.fromInvitation(
        _invitation!, 
        token,
        invitationIdOverride: widget.invitationId,
      );
      _flowState = updatedFlowState;
      
      debugPrint('Menu: Flow state after submit - mainMenuSubmitted=${updatedFlowState.mainMenuSubmitted}, '
          'companions=${updatedFlowState.companions.map((c) => "menuSubmitted:${c.menuSubmitted}").toList()}');

      if (!mounted) return;

      // Navigate to next step using the flow state we just created
      final nextStep = updatedFlowState.getNextStep();
      final nextUrl = nextStep.buildUrl(widget.invitationId, token);
      
      debugPrint('Menu: Final navigation - step: ${nextStep.step}, '
          'companionIndex: ${nextStep.companionIndex}, url: $nextUrl');
      context.go(nextUrl);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Navigate to the next step in the flow
  void _navigateToNextStep() {
    final token = _token;
    
    debugPrint('Menu _navigateToNextStep: Building flow state from _invitation');
    debugPrint('Menu _navigateToNextStep: _invitation[menuSelectionSubmitted]=${_invitation?['menuSelectionSubmitted']}');
    
    final flowState = ResponseFlowState.fromInvitation(
      _invitation!, 
      token,
      invitationIdOverride: widget.invitationId,
    );
    
    debugPrint('Menu _navigateToNextStep: flowState.mainMenuSubmitted=${flowState.mainMenuSubmitted}');
    
    final nextStep = flowState.getNextStep();
    final nextUrl = nextStep.buildUrl(widget.invitationId, token);
    
    debugPrint('Menu: Navigating to next step: ${nextStep.step}, '
        'companionIndex: ${nextStep.companionIndex}, url: $nextUrl');
    context.go(nextUrl);
  }

  /// Build a progress banner showing which person is being filled
  Widget _buildProgressBanner(String fillingForLabel) {
    final companions = (_invitation?['companions'] as List?) ?? [];
    final totalPeople = 1 + companions.length;
    
    // Calculate how many menus are complete
    int completedCount = 0;
    if (_invitation?['menuSelectionSubmitted'] == true) completedCount++;
    for (final c in companions) {
      if ((c as Map)['menuSubmitted'] == true) completedCount++;
    }
    
    final currentPersonNum = _companionIndex == null ? 1 : (_companionIndex! + 2);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kGfPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGfPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: kGfPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fillingForLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kGfPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Person $currentPersonNum of $totalPeople • $completedCount completed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kTextBody,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$completedCount / $totalPeople',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;

    // Build dynamic page title and filling label
    final String pageTitle;
    final String fillingForLabel;
    
    if (_companionIndex != null) {
      final name = _currentPersonName.isNotEmpty 
          ? _currentPersonName 
          : 'Companion ${_companionIndex! + 1}';
      pageTitle = 'Menu Selection';
      fillingForLabel = 'Selecting for: $name';
    } else {
      pageTitle = 'Menu Selection';
      fillingForLabel = 'Selecting for: You';
    }

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _isCurrentPersonDone
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Already submitted',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click Finish to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextBody,
                      ),
                    ),
                  ],
                ),
              )
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

    // Dynamic button text based on flow state
    final String buttonText;
    if (_isCurrentPersonDone) {
      buttonText = 'Continue';
    } else if (_flowState != null && !_flowState!.isComplete) {
      final nextStep = _flowState!.getNextStep();
      if (nextStep.step == ResponseStep.thankYou) {
        buttonText = 'Finish';
      } else {
        buttonText = 'Save & Continue';
      }
    } else {
      buttonText = 'Finish';
    }

    // Subtitle text
    final String subtitleText;
    if (_companionIndex != null) {
      subtitleText = 'Selecting menu for: $_currentPersonName';
    } else {
      subtitleText = 'Select the items you want.';
    }

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
                        pageTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 18),
                      
                      // Progress banner for multi-person flow
                      if (_invitation != null && 
                          ((_invitation?['companions'] as List?) ?? []).isNotEmpty) ...[
                        _buildProgressBanner(fillingForLabel),
                        const SizedBox(height: 14),
                      ],
                      
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
                                          subtitleText,
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
                                      child: Text(buttonText,
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
