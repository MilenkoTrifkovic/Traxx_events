import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';

import 'menus_widgets/menu_widgets.dart';

// assumes MenuSelectionController, MenuGroupDto, MenuItemDto are imported
// import 'menu_selection_controller.dart';

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

  final bool showDietPreferenceInPreview;

  const GuestMenuSelectionPage({
    super.key,
    required this.invitationId,
    this.companionIndex,
    this.companionName,
  })  : readOnly = false,
        selectedMenuItemIds = null,
        showDietPreferenceInPreview = false;

  /// Creates a read-only preview of menu items
  const GuestMenuSelectionPage.preview({
    super.key,
    required this.selectedMenuItemIds,
  })  : invitationId = null,
        companionIndex = null,
        companionName = null,
        readOnly = true,
        showDietPreferenceInPreview = true;

  @override
  State<GuestMenuSelectionPage> createState() => _GuestMenuSelectionPageState();
}

class _GuestMenuSelectionPageState extends State<GuestMenuSelectionPage> {
  late final MenuSelectionController _controller;
  final TextEditingController _searchController = TextEditingController();
  bool get _prefChosen => _isReadOnly || _controller.dietPref.value != null;
  String get _token => (Uri.base.queryParameters['token'] ?? '').trim();
  bool get _isReadOnly => widget.readOnly;
  bool get _showDietCard =>
      (!_isReadOnly) || widget.showDietPreferenceInPreview;

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
      _controller.loadMenuItemsOnly(
          selectedItemIds: widget.selectedMenuItemIds!);
    } else {
      _controller
          .initialize(
            invitationId: widget.invitationId!,
            token: _token,
            companionIdx: widget.companionIndex,
          )
          .then((_) => _checkNavigationAfterLoad());
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
      context.go(
        '${AppRoute.thankYou.path}?invitationId=${Uri.encodeComponent(widget.invitationId!)}'
        '&token=${Uri.encodeComponent(_token)}',
      );
      return;
    }
  }

  void _navigateToDemographics() {
    if (_isReadOnly) return;
    final compIdx = widget.companionIndex;
    var url =
        '/demographics?invitationId=${Uri.encodeComponent(widget.invitationId!)}'
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
      _controller
          .initialize(
            invitationId: widget.invitationId!,
            token: _token,
            companionIdx: widget.companionIndex,
          )
          .then((_) => _checkNavigationAfterLoad());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isReadOnly) return;

    if (_controller.dietPref.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select Veg / Non-Veg / Both first')),
      );
      return;
    }

    final result = await _controller.submitSelection(
      invitationId: widget.invitationId!,
      token: _token,
    );

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Submit failed: ${result.error ?? 'Unknown error'}')),
      );
      return;
    }

    // ✅ SAFETY: if flow is complete after menu submit → always go Thank You
    if (_controller.isFlowComplete) {
      context.go(
        '${AppRoute.thankYou.path}?invitationId=${Uri.encodeComponent(widget.invitationId!)}'
        '&token=${Uri.encodeComponent(_token)}',
      );
      return;
    }

    // Otherwise follow normal next-step routing
    final next = result.nextStep;
    if (next != null) {
      final nextUrl = next.buildUrl(widget.invitationId!, _token);
      context.go(nextUrl);
    }
  }

  void _handleContinue() {
    if (_isReadOnly) return;

    if (_controller.isFlowComplete) {
      context.go(
        '${AppRoute.thankYou.path}?invitationId=${Uri.encodeComponent(widget.invitationId!)}'
        '&token=${Uri.encodeComponent(_token)}',
      );
      return;
    }

    final nextStep = _controller.getNextStep();
    if (nextStep != null) {
      final nextUrl = nextStep.buildUrl(widget.invitationId!, _token);
      context.go(nextUrl);
    }
  }

  Widget _buildMenuList() {
    return Obx(() {
      final ungrouped = _isReadOnly
          ? _controller.filteredItems
          : _controller.dietFilteredUngrouped;

      final groups = _controller.groups;

      return Column(
        children: [
          // ✅ Show diet card in preview as well (disabled)
          if (_isReadOnly || widget.showDietPreferenceInPreview) ...[
            _DietPreferenceCard(
              controller: _controller,
              invitationId: widget.invitationId ?? 'preview',
              companionIdx: widget.companionIndex,
              compact: true,
              disabled: _isReadOnly, // ✅ disabled in preview
              previewHint: _isReadOnly, // ✅ shows hint text in preview
            ),
            const SizedBox(height: 12),
          ],

          // Keep search filters only in real flow
          if (!_isReadOnly && _controller.dietPref.value != null) ...[
            MenuSearchFilters(
              searchController: _searchController,
              controller: _controller,
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: ListView(
              children: [
                if (!_isReadOnly && groups.isNotEmpty) ...[
                  for (final g in groups) ...[
                    MenuGroupCard(group: g, controller: _controller),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                ],
                for (final it in ungrouped) ...[
                  MenuItemCardWidget(
                    item: it,
                    controller: _controller,
                    readOnly: _isReadOnly,
                  ),
                ],
              ],
            ),
          ),

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

      // ✅ Step 1: Diet gate
      if (!_isReadOnly && _controller.dietPref.value == null) {
        return Column(
          children: [
            _DietPreferenceCard(
              controller: _controller,
              invitationId: widget.invitationId!,
              companionIdx: widget.companionIndex,
              compact: false,
              disabled: false,
              previewHint: false,
            ),
            const SizedBox(height: 12),
            _PickDietInfoCard(),
          ],
        );
      }

      // ✅ Step 2: Allergens card (edit anytime after diet is chosen)
      if (!_isReadOnly) {
        return Column(
          children: [
            _AllergensCard(controller: _controller),
            const SizedBox(height: 12),

            // ✅ after allergens show the menu
            Expanded(
              child: Builder(
                builder: (_) {
                  if (_controller.isCurrentPersonDone) {
                    return MenuAlreadySubmittedCard(
                        onContinue: _handleContinue);
                  }

                  if (_controller.items.isEmpty && _controller.groups.isEmpty) {
                    return const MenuEmptyCard();
                  }

                  return _buildMenuList();
                },
              ),
            ),
          ],
        );
      }

      // ✅ Read-only / preview mode: just show menu list (diet card already handled by _showDietCard)
      if (_controller.items.isEmpty && _controller.groups.isEmpty) {
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            // BELOW: const SizedBox(height: 18),

                            Obx(() {
                              final prefChosen = _isReadOnly ||
                                  _controller.dietPref.value != null;

                              if (_isReadOnly || !prefChosen) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                children: [
                                  MenuHeaderCard(
                                    controller: _controller,
                                    onSubmit: _handleSubmit,
                                    onContinue: _handleContinue,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              );
                            }),

                            SizedBox(height: scrollH, child: _buildBody()),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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

class MenuGroupCard extends StatelessWidget {
  final MenuGroupDto group;
  final MenuSelectionController controller;
  final bool readOnly;

  const MenuGroupCard({
    super.key,
    required this.group,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // ✅ same base as ungrouped
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Obx(() {
          final picked = controller.groupPick[group.groupId];

          final visibleItems = controller.dietFilteredGroupItems(group);

          if (visibleItems.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGfPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Text(
                'No options available for your diet preference in "${group.name}".',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose 1 item',
                style: GoogleFonts.poppins(fontSize: 12, color: kTextBody),
              ),
              const SizedBox(height: 12),
              for (final it in visibleItems) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MenuSelectableTile(
                    title: it.name,
                    subtitle:
                        '${(it.isVeg == true) ? "Veg" : (it.isVeg == false) ? "Non-Veg" : ""}'
                        '${((it.isVeg == true) || (it.isVeg == false)) ? " • " : ""}'
                        '${it.categoryLabel}${it.price != null ? " • ${it.price}" : ""}',
                    description: it.description,
                    isVeg: it.isVeg,
                    selected: picked == it.id,
                    readOnly: readOnly,
                    onTap: () => controller.pickFromGroup(group.groupId, it.id),

                    // ✅ NEW: image for group item
                    imageUrl: it.imageUrl,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _DietPreferenceCard extends StatelessWidget {
  final MenuSelectionController controller;
  final String invitationId;
  final int? companionIdx;
  final bool compact;
  final bool disabled; // ✅ NEW
  final bool previewHint; // ✅ NEW

  const _DietPreferenceCard({
    required this.controller,
    required this.invitationId,
    required this.companionIdx,
    this.compact = false,
    this.disabled = false,
    this.previewHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.dietPref.value;

      Widget chip(DietPreference p, IconData icon) {
        final isSel = selected == p;

        return ChoiceChip(
          selected: isSel,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSel ? Colors.white : kGfPurple),
              const SizedBox(width: 8),
              Text(p.label),
            ],
          ),
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : kGfPurple,
          ),
          selectedColor: kGfPurple,
          backgroundColor: Colors.white,
          side: BorderSide(color: kGfPurple.withOpacity(0.35)),
          onSelected: disabled ? null : (_) => controller.setDietPreference(p),
        );
      }

      return Container(
        padding:
            EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diet preference',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              previewHint
                  ? 'Guests will choose this before selecting dishes.'
                  : 'Choose what you eat — we’ll show matching dishes only.',
              style: GoogleFonts.poppins(fontSize: 12, color: kTextBody),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                chip(DietPreference.veg, Icons.eco_outlined),
                chip(DietPreference.nonVeg, Icons.restaurant_outlined),
                chip(DietPreference.both, Icons.all_inclusive_rounded),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _PickDietInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: kGfPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGfPurple.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: kGfPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Please select Veg / Non-Veg / Both to continue.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergensCard extends StatelessWidget {
  final MenuSelectionController controller;
  final bool compact;

  const _AllergensCard({
    required this.controller,
    this.compact = false,
  });

  String _label(String k) {
    switch (k) {
      case 'tree_nuts':
        return 'Tree nuts';
      default:
        return k[0].toUpperCase() + k.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedAllergens;

      return Container(
        padding:
            EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allergens',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select allergens to hide dishes containing them.',
              style: GoogleFonts.poppins(fontSize: 12, color: kTextBody),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MenuSelectionController.allergenOptions.map((a) {
                final isOn = selected.contains(a);
                return FilterChip(
                  selected: isOn,
                  label: Text(_label(a)),
                  onSelected: (v) {
                    if (v) {
                      controller.selectedAllergens.add(a);
                    } else {
                      controller.selectedAllergens.remove(a);
                    }
                    controller.selectedAllergens.refresh();

                    // optional: if you added this method, keep selections valid
                    // controller.dropInvalidSelectionsForCurrentFilters();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
