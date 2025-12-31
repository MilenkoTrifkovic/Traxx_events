import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model for navigation items.
class NavItemData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Navigation tiles list for the sidebar.
class SidebarNavTiles extends StatelessWidget {
  final int selectedIndex;
  final List<NavItemData> items;
  final bool isExpanded;
  final ValueChanged<int> onTap;

  const SidebarNavTiles({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      itemBuilder: (context, i) {
        final bool isActive = i == selectedIndex;
        final item = items[i];

        return _NavTile(
          label: item.label,
          icon: item.icon,
          selectedIcon: item.selectedIcon,
          active: isActive,
          isExpanded: isExpanded,
          onTap: () => onTap(i),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}

/// Single navigation tile widget.
class _NavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool active;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.active,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? Colors.black : Colors.white;
    final Color bg = active ? Colors.white : Colors.transparent;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check actual available width to avoid overflow during animation
        final actuallyCollapsed = constraints.maxWidth < 100;

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              hoverColor: Colors.white.withOpacity(0.08),
              splashColor: Colors.white.withOpacity(0.12),
              highlightColor: Colors.white.withOpacity(0.06),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: actuallyCollapsed ? 0 : 12,
                  vertical: 12,
                ),
                child: Center(
                  child: actuallyCollapsed
                      ? Icon(active ? selectedIcon : icon, color: fg, size: 22)
                      : Row(
                          children: [
                            Icon(active ? selectedIcon : icon,
                                color: fg, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight:
                                      active ? FontWeight.w700 : FontWeight.w500,
                                  color: fg,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
