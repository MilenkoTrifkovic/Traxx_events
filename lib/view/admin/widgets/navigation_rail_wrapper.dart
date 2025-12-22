import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

// keep your existing imports for:
// AppColors, AppText, AppRoute, pushAndRemoveAllRoute, AuthController

class NavigationRailWrapper extends StatefulWidget {
  final Widget child;
  const NavigationRailWrapper({
    super.key,
    required this.child,
  });

  @override
  State<NavigationRailWrapper> createState() => _NavigationRailWrapperState();
}

class _NavigationRailWrapperState extends State<NavigationRailWrapper>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();

  late final AnimationController _introCtrl;
  late final Animation<Offset> _sidebarSlide;
  late final Animation<double> _sidebarFade;
  late final Animation<double> _contentFade;

  static bool _hasPlayedIntro = false;

  int _selectedIndexForLocation(String location) {
    if (location.startsWith(AppRoute.hostEvents.path)) return 0;
    if (location.startsWith(AppRoute.calendarView.path)) return 1;
    if (location.startsWith(AppRoute.hostVenues.path)) return 2;
    if (location.startsWith(AppRoute.hostMenus.path)) return 3;

    // ✅ Questions: sets + questions + setQuestions route
    if (location.startsWith(AppRoute.hostQuestionSets.path) ||
        location.startsWith(AppRoute.hostQuestions.path) ||
        location.startsWith(AppRoute.hostQuestionSetQuestions.path)) {
      return 4;
    }

    // ✅ Users
    if (location.startsWith(AppRoute.hostRoleSelection.path)) return 5;

    // ✅ Settings
    if (location.startsWith(AppRoute.hostSettings.path)) return 6;

    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async {
    switch (index) {
      case 0:
        pushAndRemoveAllRoute(AppRoute.hostEvents, context);
        return;
      case 1:
        pushAndRemoveAllRoute(AppRoute.calendarView, context);
        return;
      case 2:
        pushAndRemoveAllRoute(AppRoute.hostVenues, context);
        return;
      case 3:
        pushAndRemoveAllRoute(AppRoute.hostMenus, context);
        return;
      case 4:
        pushAndRemoveAllRoute(AppRoute.hostQuestionSets, context);
        return;
      case 5:
        pushAndRemoveAllRoute(AppRoute.hostRoleSelection, context);
        return;
      case 6:
        pushAndRemoveAllRoute(AppRoute.hostSettings, context);
        return;
      case 7:
        try {
          await authController.logout();
        } catch (_) {}
        if (context.mounted) {
          pushAndRemoveAllRoute(AppRoute.welcome, context);
        }
        return;
    }
  }

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _sidebarSlide = Tween<Offset>(
      begin: const Offset(-0.18, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));

    _sidebarFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _contentFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    if (_hasPlayedIntro) {
      _introCtrl.value = 1;
    } else {
      _hasPlayedIntro = true;
      _introCtrl.forward();
    }
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = _selectedIndexForLocation(location);

    final items = <_NavItemData>[
      _NavItemData(
        label: 'Events',
        icon: Icons.wine_bar_outlined,
        selectedIcon: Icons.wine_bar,
      ),
      _NavItemData(
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
      ),
      _NavItemData(
        label: 'Venues',
        icon: Icons.location_on_outlined,
        selectedIcon: Icons.location_on,
      ),
      _NavItemData(
        label: 'Menus',
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu,
      ),
      _NavItemData(
        label: 'Questions',
        icon: Icons.quiz_outlined,
        selectedIcon: Icons.quiz,
      ),
      _NavItemData(
        label: 'Users',
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
      ),
      _NavItemData(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
      _NavItemData(
        label: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Modern Sidebar (full-width active tab + intro slide animation)
        SlideTransition(
          position: _sidebarSlide,
          child: FadeTransition(
            opacity: _sidebarFade,
            child: _Sidebar(
              selectedIndex: selectedIndex,
              items: items,
              onTap: (i) => _onTap(context, i),
            ),
          ),
        ),

        const VerticalDivider(thickness: 1, width: 1),

        // ✅ Content (optional subtle fade on first render)
        Expanded(
          child: FadeTransition(
            opacity: _contentFade,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _Sidebar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        // ✅ richer, modern feel
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header (we’ll refine later as you said)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText.styledHeadingLarge(
                  context,
                  'Traxx',
                  color: AppColors.white,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemBuilder: (context, i) {
                  final bool isActive = i == selectedIndex;

                  final item = items[i];
                  return _NavTile(
                    label: item.label,
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    active: isActive,
                    onTap: () => onTap(i),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? Colors.black : Colors.white;
    final Color bg = active ? Colors.white : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.white.withOpacity(0.08),
        splashColor: Colors.white.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.06),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Left indicator (adds a premium feel)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),

              Icon(active ? selectedIcon : icon, color: fg, size: 22),
              const SizedBox(width: 12),

              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
