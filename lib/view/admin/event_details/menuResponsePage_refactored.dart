import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:traxx_wepapp/controller/global_controllers/menu_selection_controller.dart';

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
  late final MenuSelectionController _controller;
  final TextEditingController _searchController = TextEditingController();

  String get _token => (Uri.base.queryParameters['token'] ?? '').trim();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // Create unique tag for this instance
    final tag = 'menu_${widget.invitationId}_${widget.companionIndex}';
    
    // Delete existing controller if any
    if (Get.isRegistered<MenuSelectionController>(tag: tag)) {
      Get.delete<MenuSelectionController>(tag: tag);
    }
    
    // Create and register new controller
    _controller = Get.put(MenuSelectionController(), tag: tag);
    
    // Initialize with data
    _controller.initialize(
      invitationId: widget.invitationId,
      token: _token,
      companionIdx: widget.companionIndex,
    ).then((_) {
      // Check navigation after load
      _checkNavigationAfterLoad();
    });
  }

  void _checkNavigationAfterLoad() {
    if (!mounted) return;
    
    // If current person is already done, auto-navigate might be needed
    if (_controller.isCurrentPersonDone) {
      // Don't auto-navigate, let user click Continue
      return;
    }
    
    // If demographics not complete, redirect
    if (!_controller.isDemographicsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demographics must be completed first')),
      );
      _navigateToDemographics();
      return;
    }
    
    // If entire flow is complete, go to thank you
    if (_controller.isFlowComplete) {
      context.go('/thank-you?invitationId=${Uri.encodeComponent(widget.invitationId)}');
      return;
    }
  }

  void _navigateToDemographics() {
    final compIdx = widget.companionIndex;
    var url = '/demographics?invitationId=${Uri.encodeComponent(widget.invitationId)}'
        '&token=${Uri.encodeComponent(_token)}';
    if (compIdx != null) {
      url += '&companionIndex=$compIdx';
    }
    context.go(url);
  }

  @override
  void didUpdateWidget(covariant GuestMenuSelectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.companionIndex != oldWidget.companionIndex ||
        widget.invitationId != oldWidget.invitationId) {
      debugPrint('MenuPage: Widget params changed, reinitializing controller');
      _controller.clearSelections();
      _controller.initialize(
        invitationId: widget.invitationId,
        token: _token,
        companionIdx: widget.companionIndex,
      ).then((_) => _checkNavigationAfterLoad());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final result = await _controller.submitSelection(
      invitationId: widget.invitationId,
      token: _token,
    );

    if (!mounted) return;

    if (result.success && result.nextStep != null) {
      final nextUrl = result.nextStep!.buildUrl(widget.invitationId, _token);
      context.go(nextUrl);
    } else if (!result.success && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: ${result.error}')),
      );
    }
  }

  void _handleContinue() {
    final nextStep = _controller.getNextStep();
    if (nextStep != null) {
      final nextUrl = nextStep.buildUrl(widget.invitationId, _token);
      context.go(nextUrl);
    }
  }

  // ---------------------------------------------------------------------------
  // UI Widgets
  // ---------------------------------------------------------------------------

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
          Text('$label: ', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildProgressBanner() {
    return Obx(() {
      if (!_controller.hasCompanions) return const SizedBox.shrink();
      
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
                    _controller.fillingForLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kGfPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Person ${_controller.currentPersonNumber} of ${_controller.totalPeople} • ${_controller.completedMenuCount} completed',
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
                '${_controller.completedMenuCount} / ${_controller.totalPeople}',
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
    });
  }

  Widget _buildSearchAndFilters() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _controller.setSearchQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search dish name, e.g. "rice"',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Obx(() => Row(
              children: [
                _filterChip(
                  label: 'All (${_controller.items.length})',
                  selected: _controller.vegFilter.value == null,
                  onTap: () => _controller.setVegFilter(null),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Veg (${_controller.vegCount})',
                  selected: _controller.vegFilter.value == true,
                  onTap: () => _controller.setVegFilter(true),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Non-Veg (${_controller.nonVegCount})',
                  selected: _controller.vegFilter.value == false,
                  onTap: () => _controller.setVegFilter(false),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearFilters();
                  },
                  child: const Text('Clear'),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItemDto item) {
    return Obx(() {
      final selected = _controller.isSelected(item.id);

      final Color tint = item.isVeg == true
          ? Colors.green.shade50
          : item.isVeg == false
              ? Colors.red.shade50
              : Colors.grey.shade50;

      final Color border = item.isVeg == true
          ? Colors.green.shade400
          : item.isVeg == false
              ? Colors.red.shade400
              : kBorder;

      final foodTypeLabel = item.isVeg == true
          ? 'Veg'
          : item.isVeg == false
              ? 'Non-Veg'
              : (item.foodType ?? '');

      final subtitle = foodTypeLabel.isEmpty
          ? item.categoryLabel
          : '$foodTypeLabel • ${item.categoryLabel}';

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
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _controller.toggleItem(item.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    _FoodTypeIcon(isVeg: item.isVeg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: kTextDark,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: kTextBody,
                              ),
                            ),
                          if (item.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: kTextBody.withOpacity(0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? border : Colors.transparent,
                        border: Border.all(
                          color: selected ? border : kBorder,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAlreadySubmittedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
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
            'Click Continue to proceed',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: kTextBody,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGfPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Text(
        'No menu items available for this event.',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMenuList() {
    return Obx(() {
      final list = _controller.filteredItems;
      
      return Column(
        children: [
          _buildSearchAndFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => _buildMenuItemCard(list[i]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _summaryPill('Items', _controller.selectedCount.toString()),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildBody() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading menu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.errorMessage.value,
                style: GoogleFonts.poppins(fontSize: 14, color: kTextBody),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      if (_controller.isCurrentPersonDone) {
        return _buildAlreadySubmittedView();
      }

      if (_controller.items.isEmpty) {
        return _buildEmptyView();
      }

      return _buildMenuList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final viewportH = MediaQuery.of(ctx).size.height;
        final boundedH = constraints.hasBoundedHeight;
        final maxH = boundedH ? constraints.maxHeight : viewportH;

        final scrollH = (maxH - 280).clamp(260.0, 800.0);

        return SizedBox(
          width: double.infinity,
          height: boundedH ? maxH : null,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: gfBackground)),
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress banner
                            _buildProgressBanner(),
                            Obx(() => _controller.hasCompanions 
                                ? const SizedBox(height: 12) 
                                : const SizedBox.shrink()),
                            
                            Text(
                              'Menu Selection',
                              style: GoogleFonts.poppins(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            
                            // Header card with action button
                            _buildHeaderCard(),
                            const SizedBox(height: 14),
                            
                            // Main content
                            SizedBox(
                              height: scrollH,
                              child: _buildBody(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Loading overlay
              Obx(() => _controller.isSubmitting.value
                  ? Positioned.fill(
                      child: Container(
                        color: gfBackground.withOpacity(0.35),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: kGfPurple,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeaderCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
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
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        _controller.eventName.value.isEmpty 
                            ? 'Menu Selection' 
                            : _controller.eventName.value,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      )),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        _controller.companionIndex.value != null
                            ? 'Selecting menu for: ${_controller.currentPersonName.value}'
                            : 'Select the items you want.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kTextBody,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Obx(() => SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _controller.isSubmitting.value
                ? null
                : (_controller.isCurrentPersonDone
                    ? _handleContinue
                    : _handleSubmit),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGfPurple,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(_controller.buttonText),
          ),
        )),
      ],
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
