import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/menus_list_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_menu_popup_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/sort_menus.dart';
import 'package:traxx_wepapp/widgets/bottom_scrollbar.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';
import 'package:go_router/go_router.dart';

/// A screen that displays the menu management interface.
///
class MenusView extends StatefulWidget {
  const MenusView({super.key});

  @override
  State<MenusView> createState() => _MenusViewState();
}

class _MenusViewState extends State<MenusView> {
  late MenusScreenController createController;
  late MenusListController listController;
  late final SnackbarMessageController snackbarMessageController;

  @override
  void initState() {
    super.initState();
    snackbarMessageController = Get.find<SnackbarMessageController>();
    createController = Get.find<MenusScreenController>();
    listController = Get.find<MenusListController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (listController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: (listController.filteredMenuSets.isNotEmpty ||
                        listController.menuSets.isNotEmpty)
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: _buildMenusListSection(context),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenusListSection(BuildContext context) {
    final hasAnyData = listController.filteredMenuSets.isNotEmpty ||
        listController.menuSets.isNotEmpty;

    if (!hasAnyData) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: EmptyState(
          title: 'No Menu Sets Found',
          imageAsset: Constants.emptyMenu,
          description:
              'Create your first menu set by tapping the button below.',
          buttonText: 'Add First Menu Set',
          onButtonPressed: () {
            showDialog(
              context: context,
              builder: (_) => CreateMenuPopupView(controller: createController),
            ).then((value) async {
              if (value == true) {
                try {
                  showLoadingIndicator();
                  final createdMenuSet = await createController.submitForm();
                  listController.addMenuSet(createdMenuSet);

                  snackbarMessageController.showSuccessMessage(
                    'Menu set created successfully.',
                  );

                  if (createdMenuSet.id.isNotEmpty) {
                    context.push(
                        '${AppRoute.hostMenus.path}/${createdMenuSet.id}');
                  }
                } catch (_) {
                  snackbarMessageController
                      .showErrorMessage('Error creating menu set');
                } finally {
                  hideLoadingIndicator();
                }
              }
            });
          },
        ),
      );
    }

    final items = listController.filteredMenuSets;
    final theme = Theme.of(context);

    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SortMenus(),
          AppSpacing.verticalXxxs(context),

          // ✅ Local Poppins theme for this table area
          Theme(
            data: theme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
              primaryTextTheme:
                  GoogleFonts.poppinsTextTheme(theme.primaryTextTheme),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth;
                final compact = available < 900;

                // ✅ Minimum readable width:
                // small screens scroll, big screens fit full width
                final minTableWidth = compact ? 640.0 : 980.0;
                final tableWidth =
                    available > minTableWidth ? available : minTableWidth;

                return BottomHScrollbar(
                  minWidth: tableWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: tableWidth, maxWidth: tableWidth),
                    child: _buildMenusTable(
                      context,
                      items,
                      compact: compact,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenusTable(
    BuildContext context,
    List<MenuModel> items, {
    required bool compact,
  }) {
    final headerPadH = compact ? 14.0 : 24.0;
    final rowPadH = compact ? 14.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // HEADER
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.symmetric(horizontal: headerPadH, vertical: 14),
            child: Row(
              children: [
                Expanded(
                    flex: 4, child: _tableHeaderText('Menu Name', compact)),
                Expanded(
                    flex: 4, child: _tableHeaderText('Description', compact)),
                Expanded(flex: 2, child: _tableHeaderText('Created', compact)),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _tableHeaderText('Actions', compact),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),

          // BODY
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 0.4,
              color: Color(0xFFE5E7EB),
            ),
            itemBuilder: (context, index) {
              final menuSet = items[index];
              final isLast = index == items.length - 1;
              return _buildMenuTableRow(
                context,
                menuSet,
                compact: compact,
                rowPadH: rowPadH,
                isLast: isLast,
              );
            },
          ),
        ],
      ),
    );
  }

  Text _tableHeaderText(String text, bool compact) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: compact ? 13.5 : 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: const Color(0xFF111827),
        ),
      );

  Widget _buildMenuTableRow(
    BuildContext context,
    MenuModel menu, {
    required bool compact,
    required double rowPadH,
    bool isLast = false,
  }) {
    void openDetails() {
      if (menu.id.isEmpty) return;
      context.push('${AppRoute.hostMenus.path}/${menu.id}');
    }

    final thumbSize = compact ? 44.0 : 56.0;
    final nameSize = compact ? 14.5 : 16.0;

    return InkWell(
      onTap: openDetails,
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.02),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: rowPadH,
          vertical: compact ? 12 : 14,
        ),
        child: Row(
          children: [
            // NAME + IMAGE
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: thumbSize,
                      height: thumbSize,
                      child: _buildThumbImage(menu),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      menu.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: nameSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // DESCRIPTION
            Expanded(
              flex: 4,
              child: Text(
                menu.description?.isNotEmpty == true
                    ? menu.description!
                    : 'Menu for your events',
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),

            // CREATED
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(menu.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),

            // ACTIONS
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: compact
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'View',
                            icon: const Icon(Icons.remove_red_eye_outlined,
                                size: 18),
                            onPressed: openDetails,
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Color(0xFFEF4444)),
                            onPressed: listController.isDeleting.value
                                ? null
                                : () => _confirmDelete(context, menu),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: openDetails,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              'View',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: listController.isDeleting.value
                                ? null
                                : () => _confirmDelete(context, menu),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MenuModel menu) async {
    if (menu.id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete menu set?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete "${menu.name}" and all menu items inside this set.\n\n'
          'This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await listController.deleteMenuSetAndItems(menu);
      if (ok) {
        snackbarMessageController.showSuccessMessage(
          'Menu "${menu.name}" and its items were deleted.',
        );
      } else {
        snackbarMessageController.showErrorMessage(
          'Failed to delete "${menu.name}". Please try again.',
        );
      }
    }
  }

  Widget _buildThumbImage(MenuModel menu) {
    final url = menu.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() => Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.restaurant_menu,
          size: 20,
          color: Colors.grey.shade500,
        ),
      );

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
