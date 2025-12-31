import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar_header.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar_nav_tiles.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar_footer.dart';

/// The main sidebar widget containing header, nav tiles, and footer.
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<NavItemData> items;
  final ValueChanged<int> onTap;
  final bool isExpanded;
  final String organisationName;
  final String? organisationPhotoUrl;
  final VoidCallback onToggleExpand;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
    required this.isExpanded,
    required this.organisationName,
    this.organisationPhotoUrl,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final targetWidth = isExpanded ? 232.0 : 72.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: targetWidth,
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actuallyCollapsed = constraints.maxWidth < 150;

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header: Toggle button + Logo + Organisation name
                SidebarHeader(
                  isExpanded: isExpanded,
                  actuallyCollapsed: actuallyCollapsed,
                  organisationName: organisationName,
                  organisationPhotoUrl: organisationPhotoUrl,
                  onToggleExpand: onToggleExpand,
                ),

                const SizedBox(height: 12),

                // Navigation tiles
                Expanded(
                  child: SidebarNavTiles(
                    selectedIndex: selectedIndex,
                    items: items,
                    isExpanded: isExpanded,
                    onTap: onTap,
                  ),
                ),

                // Footer: App name + Version
                SidebarFooter(
                  isExpanded: isExpanded,
                  actuallyCollapsed: actuallyCollapsed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
