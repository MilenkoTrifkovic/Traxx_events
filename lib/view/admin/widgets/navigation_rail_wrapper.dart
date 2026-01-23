import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar_nav_tiles.dart';

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
  bool _isExpanded = true; // Track expanded/collapsed state
  bool _initialStateSet =
      false; // Track if we've set initial state based on screen size

  int _selectedIndexForLocation(String location) {
    if (location.startsWith(AppRoute.hostEvents.path)) return 0;
    if (location.startsWith(AppRoute.calendarView.path)) return 1;
    if (location.startsWith(AppRoute.hostVenues.path)) return 2;
    if (location.startsWith(AppRoute.hostMenus.path)) return 3;

    // ✅ Questions
    if (location.startsWith(AppRoute.hostQuestionSets.path) ||
        location.startsWith(AppRoute.hostQuestions.path) ||
        location.startsWith(AppRoute.hostQuestionSetQuestions.path) ||
        location.startsWith(AppRoute.hostQuestionRules.path)) {
      return 4;
    }

    // ✅ Users
    if (location.startsWith(AppRoute.hostRoleSelection.path)) return 5;

    // ✅ Buy Credits
    if (location.startsWith(AppRoute.hostBuyCredits.path)) return 6;

    // ✅ Settings
    if (location.startsWith(AppRoute.hostSettings.path)) return 7;

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

      // ✅ Users
      case 5:
        pushAndRemoveAllRoute(AppRoute.hostRoleSelection, context);
        return;

      // ✅ Buy Credits
      case 6:
        pushAndRemoveAllRoute(AppRoute.hostBuyCredits, context);
        return;

      // ✅ Settings
      case 7:
        pushAndRemoveAllRoute(AppRoute.hostSettings, context);
        return;

      // ✅ Logout (FIXED index)
      case 8:
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Set initial collapsed state for phones
    if (!_initialStateSet) {
      _initialStateSet = true;
      if (ScreenSize.isPhone(context)) {
        _isExpanded = false;
      }
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

    // Auto-collapse on phone screens
    final bool isPhone = ScreenSize.isPhone(context);
    final bool shouldBeExpanded = isPhone ? _isExpanded : _isExpanded;

    final items = <NavItemData>[
      const NavItemData(
        label: 'Events',
        icon: Icons.wine_bar_outlined,
        selectedIcon: Icons.wine_bar,
      ),
      const NavItemData(
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
      ),
      const NavItemData(
        label: 'Venues',
        icon: Icons.location_on_outlined,
        selectedIcon: Icons.location_on,
      ),
      const NavItemData(
        label: 'Menus',
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu,
      ),
      const NavItemData(
        label: 'Questions',
        icon: Icons.quiz_outlined,
        selectedIcon: Icons.quiz,
      ),
      const NavItemData(
        label: 'Users',
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
      ),
      const NavItemData(
        label: 'Buy Events',
        icon: Icons.credit_card_outlined,
        selectedIcon: Icons.credit_card,
      ),
      const NavItemData(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
      const NavItemData(
        label: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
      ),
    ];

    // Get organisation name
    final organisationName = Get.isRegistered<OrganisationController>()
        ? Get.find<OrganisationController>().getOrganisationName()
        : 'Event Manager';

    // Get organisation photo URL
    final organisationPhotoUrl = Get.isRegistered<OrganisationController>()
        ? Get.find<OrganisationController>().getOrganisationPhotoUrl()
        : null;

    final sidebarWidget = SlideTransition(
      position: _sidebarSlide,
      child: FadeTransition(
        opacity: _sidebarFade,
        child: Sidebar(
          selectedIndex: selectedIndex,
          items: items,
          onTap: (i) => _onTap(context, i),
          isExpanded: shouldBeExpanded,
          organisationName: organisationName,
          organisationPhotoUrl: organisationPhotoUrl,
          onToggleExpand: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
      ),
    );

    final contentWidget = FadeTransition(
      opacity: _contentFade,
      child: widget.child,
    );

    // On phone: Stack layout (overlay) | On larger screens: Row layout (push)
    if (isPhone) {
      return Stack(
        children: [
          // Content with left padding when collapsed (pushes content)
          Padding(
            padding: EdgeInsets.only(left: _isExpanded ? 0 : 72.0),
            child: contentWidget,
          ),

          // Backdrop/scrim when expanded
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

          // Navigation rail (overlay)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: sidebarWidget,
          ),
        ],
      );
    }

    // Larger screens: Row layout (pushes content)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sidebarWidget,
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: contentWidget),
      ],
    );
  }
}
