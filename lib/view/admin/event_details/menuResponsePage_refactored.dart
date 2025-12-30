import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'menus_widgets/menu_widgets.dart';

class GuestMenuSelectionPage extends StatefulWidget {
  final String? invitationId;
  
  /// Companion index: null = main guest, 0+ = companion
  final int? companionIndex;
  
  /// Display name for companion (optional, for UI)
  final String? companionName;
  
  /// Whether the page is in read-only preview mode
  final bool readOnly;
  
  /// Pre-selected item IDs to display in read-only mode
  final List<String>? selectedMenuItemIds;
  
  const GuestMenuSelectionPage({
    super.key, 
    required String this.invitationId,
    this.companionIndex,
    this.companionName,
  }) : readOnly = false,
       selectedMenuItemIds = null;
  
  /// Creates a read-only preview of menu items
  const GuestMenuSelectionPage.preview({
    super.key,
    required List<String> this.selectedMenuItemIds,
  }) : invitationId = null,
       companionIndex = null,
       companionName = null,
       readOnly = true;

  @override
  State<GuestMenuSelectionPage> createState() => _GuestMenuSelectionPageState();
}

class _GuestMenuSelectionPageState extends State<GuestMenuSelectionPage> {
  late final MenuSelectionController _controller;
  final TextEditingController _searchController = TextEditingController();

  String get _token => (Uri.base.queryParameters['token'] ?? '').trim();
  bool get _isReadOnly => widget.readOnly;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final tag = _isReadOnly 
        ? 'menu_preview_${widget.selectedMenuItemIds?.hashCode}'
        : 'menu_${widget.invitationId}_${widget.companionIndex}';
    
    if (Get.isRegistered<MenuSelectionController>(tag: tag)) {
      Get.delete<MenuSelectionController>(tag: tag);
    }
    
    _controller = Get.put(MenuSelectionController(), tag: tag);
    
    if (_isReadOnly) {
      // Load only menu items for preview
      _controller.loadMenuItemsOnly(
        selectedItemIds: widget.selectedMenuItemIds!,
      );
    } else {
      // Normal flow
      _controller.initialize(
        invitationId: widget.invitationId!,
        token: _token,
        companionIdx: widget.companionIndex,
      ).then((_) => _checkNavigationAfterLoad());
    }
  }

  void _checkNavigationAfterLoad() {
    if (!mounted || _isReadOnly) return;
    
    if (_controller.isCurrentPersonDone) return;
    
    if (!_controller.isDemographicsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demographics must be completed first')),
      );
      _navigateToDemographics();
      return;
    }
    
    if (_controller.isFlowComplete) {
      context.go('/thank-you?invitationId=${Uri.encodeComponent(widget.invitationId!)}');
    }
  }

  void _navigateToDemographics() {
    if (_isReadOnly) return;
    final compIdx = widget.companionIndex;
    var url = '/demographics?invitationId=${Uri.encodeComponent(widget.invitationId!)}'
        '&token=${Uri.encodeComponent(_token)}';
    if (compIdx != null) url += '&companionIndex=$compIdx';
    context.go(url);
  }

  @override
  void didUpdateWidget(covariant GuestMenuSelectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_isReadOnly) return;
    
    if (widget.companionIndex != oldWidget.companionIndex ||
        widget.invitationId != oldWidget.invitationId) {
      _controller.clearSelections();
      _controller.initialize(
        invitationId: widget.invitationId!,
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
    if (_isReadOnly) return;
    
    final result = await _controller.submitSelection(
      invitationId: widget.invitationId!,
      token: _token,
    );

    if (!mounted) return;

    if (result.success && result.nextStep != null) {
      final nextUrl = result.nextStep!.buildUrl(widget.invitationId!, _token);
      context.go(nextUrl);
    } else if (!result.success && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: ${result.error}')),
      );
    }
  }

  void _handleContinue() {
    if (_isReadOnly) return;
    
    final nextStep = _controller.getNextStep();
    if (nextStep != null) {
      final nextUrl = nextStep.buildUrl(widget.invitationId!, _token);
      context.go(nextUrl);
    }
  }

  Widget _buildMenuList() {
    return Obx(() {
      final list = _controller.filteredItems;
      
      return Column(
        children: [
          // Hide search/filters in read-only mode
          if (!_isReadOnly) ...[
            MenuSearchFilters(
              searchController: _searchController,
              controller: _controller,
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => MenuItemCardWidget(
                item: list[i],
                controller: _controller,
                readOnly: _isReadOnly,
              ),
            ),
          ),
          // Hide summary pill in read-only mode
          if (!_isReadOnly) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MenuSummaryPill(
                  count: _controller.selectedCount,
                  label: 'selected',
                  color: kGfPurple,
                ),
              ],
            ),
          ],
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
        return MenuErrorCard(message: _controller.errorMessage.value);
      }

      // Skip "already submitted" in read-only mode
      if (!_isReadOnly && _controller.isCurrentPersonDone) {
        return MenuAlreadySubmittedCard(onContinue: _handleContinue);
      }

      if (_controller.items.isEmpty) {
        return const MenuEmptyCard();
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
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hide progress banner in read-only mode
                            if (!_isReadOnly) ...[
                              MenuProgressBanner(controller: _controller),
                              Obx(() => _controller.hasCompanions 
                                  ? const SizedBox(height: 12) 
                                  : const SizedBox.shrink()),
                            ],
                            Text(
                              'Menu Selection',
                              style: GoogleFonts.poppins(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Hide header card with action button in read-only mode
                            if (!_isReadOnly) ...[
                              MenuHeaderCard(
                                controller: _controller,
                                onSubmit: _handleSubmit,
                                onContinue: _handleContinue,
                              ),
                              const SizedBox(height: 14),
                            ],
                            SizedBox(height: scrollH, child: _buildBody()),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Hide loading overlay in read-only mode
              if (!_isReadOnly)
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
}
