import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/menus_details_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/menu_category_helper.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

class MenuSetDetailsView extends StatelessWidget {
  final String menuId;

  const MenuSetDetailsView({super.key, required this.menuId});

  Widget _buildDetailsAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- SAFELY replace existing controller if present (fixes the Rxn type mismatch)
    if (Get.isRegistered<MenuSetDetailsController>(tag: menuId)) {
      Get.delete<MenuSetDetailsController>(tag: menuId);
    }
    final controller = Get.put(
      MenuSetDetailsController(menuId: menuId),
      tag: menuId,
    );

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final menuSet = controller.menuSet.value;
      if (menuSet == null) {
        return const Center(child: Text('Menu set not found'));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailsAppBar(context, menuSet.name),
          SingleChildScrollView(
            padding: AppPadding.all(context, paddingType: Sizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildMenuSetHeader(context, controller, menuSet),
                // AppSpacing.verticalSm(context),
                _buildItemsSection(context, controller),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ---------- HEADER (MenuModel) ----------
  Widget _buildMenuSetHeader(
    BuildContext context,
    MenuSetDetailsController controller,
    MenuModel menuSet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: _buildCoverImage(menuSet),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name + description + created date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menuSet.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (menuSet.description != null &&
                          menuSet.description!.isNotEmpty)
                        Text(
                          menuSet.description!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        controller.formatDate(menuSet.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppSecondaryButton(
                      text: 'Edit Menu Set',
                      icon: Icons.edit_outlined,
                      onPressed: () {
                        // TODO: Edit menu set popup if needed
                      },
                    ),
                    const SizedBox(height: 8),
                    AppSecondaryButton(
                      text: menuSet.isDisabled ? 'Enable' : 'Disable',
                      icon: menuSet.isDisabled
                          ? Icons.toggle_on_outlined
                          : Icons.toggle_off_outlined,
                      onPressed: () {
                        // TODO: toggle enable/disable
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(MenuModel menuSet) {
    final url = menuSet.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _coverPlaceholder(),
      );
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAccent.withOpacity(0.18),
            AppColors.primaryAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 64,
          color: AppColors.primaryAccent.withOpacity(0.7),
        ),
      ),
    );
  }

  // ---------- ITEMS SECTION (single table grouped by category) ----------
  Widget _buildItemsSection(
    BuildContext context,
    MenuSetDetailsController controller,
  ) {
    return Obx(() {
      if (controller.isItemsLoading.value) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final items = controller.filteredItems;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + Add Item button (top-right)
          _buildFilterSortBar(context, controller),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Menu Items',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                text: 'Add New Item',
                icon: Icons.add,
                onPressed: () async {
                  final created = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false, // ← IMPORTANT
                    builder: (_) => AddMenuItemDialog(
                      controller: controller,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // If no items
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                    color: Colors.black.withOpacity(0.03),
                  ),
                ],
              ),
              child: Text(
                'No menu items added yet for this set.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            // Group items by category and render each group
            _buildGroupedItemsTable(items, controller),
        ],
      );
    });
  }

  Widget _buildFilterSortBar(
    BuildContext context,
    MenuSetDetailsController controller,
  ) {
    final theme = Theme.of(context);
    final org = Get.find<OrganisationController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.02),
          ),
        ],
      ),
      child: Column(
        children: [
          // ROW 1: Search + Sort
          Row(
            children: [
              // Search by item name / description
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: controller.setSearchQuery,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search items…',
                    hintStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Sort dropdown
              Expanded(
                flex: 2,
                child: Obx(() {
                  final showPrices = org.showMenuItemPrices.value;

                  // ✅ allowed sort options based on toggle
                  final allowedSorts = <MenuItemsSortType>[
                    MenuItemsSortType.nameAZ,
                    MenuItemsSortType.nameZA,
                    if (showPrices) MenuItemsSortType.priceLowHigh,
                    if (showPrices) MenuItemsSortType.priceHighLow,
                    MenuItemsSortType.dateNewest,
                    MenuItemsSortType.dateOldest,
                  ];

                  // ✅ If currently on a price sort but prices are hidden, force fallback
                  if (!showPrices &&
                      (controller.sortType.value ==
                              MenuItemsSortType.priceLowHigh ||
                          controller.sortType.value ==
                              MenuItemsSortType.priceHighLow)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (controller.sortType.value !=
                          MenuItemsSortType.nameAZ) {
                        controller.setSortType(MenuItemsSortType.nameAZ);
                      }
                    });
                  }

                  String labelFor(MenuItemsSortType t) {
                    switch (t) {
                      case MenuItemsSortType.nameAZ:
                        return 'Name (A–Z)';
                      case MenuItemsSortType.nameZA:
                        return 'Name (Z–A)';
                      case MenuItemsSortType.priceLowHigh:
                        return 'Price (Low–High)';
                      case MenuItemsSortType.priceHighLow:
                        return 'Price (High–Low)';
                      case MenuItemsSortType.dateNewest:
                        return 'Date (Newest)';
                      case MenuItemsSortType.dateOldest:
                        return 'Date (Oldest)';
                    }
                  }

                  // ✅ pick a safe value (in case current isn't allowed anymore)
                  final current =
                      allowedSorts.contains(controller.sortType.value)
                          ? controller.sortType.value
                          : MenuItemsSortType.nameAZ;

                  return DropdownButtonFormField<MenuItemsSortType>(
                    value: current,
                    onChanged: (v) {
                      if (v != null) controller.setSortType(v);
                    },
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      labelStyle: GoogleFonts.poppins(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    items: allowedSorts
                        .map((t) => DropdownMenuItem<MenuItemsSortType>(
                              value: t,
                              child: Text(
                                labelFor(t),
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ))
                        .toList(),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ROW 2: Category + Price range
          Row(
            children: [
              // Category filter
              Expanded(
                flex: 2,
                child: Obx(
                  () => DropdownButtonFormField<String?>(
                    key: ValueKey(controller.selectedCategory.value),
                    initialValue: controller.selectedCategory.value,
                    onChanged: (v) => controller.setCategoryFilter(v),
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: GoogleFonts.poppins(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    items: MenuCategoryHelper.getCategoryFilterItems()
                        .map((item) => DropdownMenuItem<String?>(
                              value: item.value,
                              child: Text(
                                item.child is Text
                                    ? (item.child as Text).data ?? ''
                                    : '',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // ✅ Price range (only when showPrices == true)
              Obx(() {
                final showPrices = org.showMenuItemPrices.value;
                if (!showPrices) return const SizedBox.shrink();

                return Expanded(
                  flex: 2, // price fields take remaining space
                  child: Row(
                    children: [
                      const SizedBox(width: 16),

                      // Min price
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: controller.setMinPrice,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Min price',
                            prefixText: '\$',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Max price
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: controller.setMaxPrice,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Max price',
                            prefixText: '\$',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedItemsTable(
    List<MenuItem> items,
    MenuSetDetailsController controller,
  ) {
    final org = Get.find<OrganisationController>();

    // group manually by category (String-based)
    final Map<String, List<MenuItem>> grouped = {};
    for (final i in items) {
      grouped.putIfAbsent(i.category, () => []).add(i);
    }

    return Obx(() {
      final showPrices = org.showMenuItemPrices.value;

      return Column(
        children: grouped.entries.map((entry) {
          final category = entry.key;
          final list = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _prettyCategory(category),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                      color: Colors.black.withOpacity(0.03),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // header row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Item',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Category',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),

                          // ✅ Price header only when enabled
                          if (showPrices)
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Price',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),

                          Expanded(
                            flex: 2,
                            child: Text(
                              'Created',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Actions',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (context, index) => _buildItemRow(
                        context,
                        list[index],
                        controller,
                        showPrices, // ✅ pass down
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildItemRow(
    BuildContext context,
    MenuItem item,
    MenuSetDetailsController controller,
    bool showPrices,
  ) {
    final theme = Theme.of(context);

    Widget fallbackBox() {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 26,
          color: theme.colorScheme.primary,
        ),
      );
    }

    Widget thumb() {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item.imageUrl!,
            width: 56, // was 40
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallbackBox(),
          ),
        );
      }
      return fallbackBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _foodTypeBadge(item.foodType), // NEW
                const SizedBox(width: 8),
                thumb(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16, // bigger
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category chip
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.primary.withOpacity(0.06),
                ),
                child: Text(
                  _prettyCategory(item.category),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

          // ✅ Price cell only when enabled
          if (showPrices)
            Expanded(
              flex: 2,
              child: Text(
                item.price != null
                    ? '\$${item.price!.toStringAsFixed(0)}'
                    : '-',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF111827),
                ),
              ),
            ),

          // Created date
          Expanded(
            flex: 2,
            child: Text(
              controller.formatDate(item.createdAt),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Actions: Edit / Delete
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit item',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () async {
                      final updated = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false, // ← same here
                        builder: (_) => AddMenuItemDialog(
                          controller: controller,
                          existing: item,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete item',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.redAccent,
                    onPressed: () {
                      controller.deleteItem(item);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodTypeBadge(FoodType? type) {
    if (type == null) return const SizedBox(width: 0, height: 0);

    final bool isVeg = type == FoodType.veg;
    final Color borderColor = isVeg ? Colors.green : Colors.redAccent;
    final Color fillColor = borderColor;

    return Tooltip(
      message: isVeg ? 'Veg' : 'Non-veg',
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  String _prettyCategory(String category) {
    // Category is already formatted by MenuCategoryHelper
    return category;
  }
}

class AddMenuItemDialog extends StatefulWidget {
  final MenuSetDetailsController controller;
  final MenuItem? existing; // if provided => edit mode

  const AddMenuItemDialog({
    super.key,
    required this.controller,
    this.existing,
  });

  @override
  State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _descC;
  late final TextEditingController _priceC;
  late final TextEditingController _imageUrlC; // ← NEW
  String _category = 'Other'; // Changed from MenuCategory enum to String
  bool _isSaving = false;
  bool _isUploadingImage = false;
  FoodType _foodType = FoodType.veg;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.existing?.name ?? '');
    _descC = TextEditingController(text: widget.existing?.description ?? '');
    _priceC =
        TextEditingController(text: widget.existing?.price?.toString() ?? '');
    _imageUrlC =
        TextEditingController(text: widget.existing?.imageUrl ?? ''); // ← NEW
    if (widget.existing != null) {
      _category = widget.existing!.category;
      _foodType = widget.existing!.foodType ?? FoodType.veg; // NEW
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _priceC.dispose();
    _imageUrlC.dispose(); // ← NEW
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isUploadingImage = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // important for web
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploadingImage = false);
        return; // user cancelled
      }

      final file = result.files.single;
      if (file.bytes == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      // infer content-type from extension (optional)
      final ext = file.extension?.toLowerCase();
      String contentType;
      switch (ext) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final storageRef =
          FirebaseStorage.instance.ref().child('menu_item_images').child(
                '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
              );

      await storageRef.putData(
        file.bytes!,
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _imageUrlC.text = downloadUrl; // reuse existing field
        _isUploadingImage = false;
      });
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() => _isUploadingImage = false);
      Get.snackbar('Error', 'Failed to upload image');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameC.text.trim();
    final desc = _descC.text.trim().isEmpty ? null : _descC.text.trim();
    final price = _priceC.text.trim().isEmpty
        ? null
        : double.tryParse(_priceC.text.trim());
    final imageUrl =
        _imageUrlC.text.trim().isEmpty ? null : _imageUrlC.text.trim(); // ← NEW

    setState(() => _isSaving = true);

    try {
      if (widget.existing == null) {
        // create
        await widget.controller.createItem(
          name: name,
          category: _category,
          description: desc,
          price: price,
          imageUrl: imageUrl, // ← NEW
          foodType: _foodType,
        );
      } else {
        final updated = widget.existing!.copyWith(
          name: name,
          category: _category,
          description: desc,
          price: price,
          imageUrl: imageUrl, // ← NEW
          updatedAt: DateTime.now(),
          foodType: _foodType,
        );
        await widget.controller.updateItem(updated);
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error saving menu item: $e');
      Get.snackbar('Error', 'Failed to save item');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      // 2) DON’T CLOSE ON OUTSIDE TAP: this is handled in showDialog() call (see below)
      title: Text(isEdit ? 'Edit Item' : 'Add New Item',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: MenuCategoryHelper.getCategoryDropdownItems(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<FoodType>(
                initialValue: _foodType,
                decoration: const InputDecoration(labelText: 'Food type'),
                items: const [
                  DropdownMenuItem(
                    value: FoodType.veg,
                    child: Text('Veg'),
                  ),
                  DropdownMenuItem(
                    value: FoodType.nonVeg,
                    child: Text('Non-veg'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _foodType = v);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceC,
                decoration: const InputDecoration(labelText: 'Price (USD)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v.trim()) == null
                      ? 'Enter valid number'
                      : null;
                },
              ),
              const SizedBox(height: 12),

              // ---- IMAGE UPLOAD + URL ----
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlC,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      _isUploadingImage ? 'Uploading...' : 'Upload',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_imageUrlC.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 100,
                    child: Image.network(
                      _imageUrlC.text,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),

              TextFormField(
                controller: _descC,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Save' : 'Create', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}
