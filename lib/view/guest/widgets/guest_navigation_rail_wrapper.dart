import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar_nav_tiles.dart';

/// Navigation rail wrapper for guest pages
/// Provides consistent navigation and layout for authenticated guest users
class GuestNavigationRailWrapper extends StatefulWidget {
  final Widget child;
  
  const GuestNavigationRailWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GuestNavigationRailWrapper> createState() => _GuestNavigationRailWrapperState();
}

class _GuestNavigationRailWrapperState extends State<GuestNavigationRailWrapper>
    with SingleTickerProviderStateMixin {
  final GuestSessionController guestSession = Get.find<GuestSessionController>();

  late final AnimationController _introCtrl;
  late final Animation<Offset> _sidebarSlide;
  late final Animation<double> _sidebarFade;
  late final Animation<double> _contentFade;

  static bool _hasPlayedIntro = false;
  bool _isExpanded = true;
  bool _initialStateSet = false;

  int _selectedIndexForLocation(String location) {
    if (location.startsWith(AppRoute.guestResponsesPreview.path)) return 0;
    if (location.startsWith(AppRoute.guestDemographicsView.path)) return 1;
    if (location.startsWith(AppRoute.guestMenuSelectionView.path)) return 2;
    if (location.startsWith(AppRoute.guestFeed.path)) return 3;
    // Add more guest routes here as needed
    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async {
    switch (index) {
      case 0:
        pushAndRemoveAllRoute(AppRoute.guestResponsesPreview, context);
        return;
      case 1:
        pushAndRemoveAllRoute(AppRoute.guestDemographicsView, context);
        return;
      case 2:
        pushAndRemoveAllRoute(AppRoute.guestMenuSelectionView, context);
        return;
      case 3:
        pushAndRemoveAllRoute(AppRoute.guestFeed, context);
        return;
      case 4:
        // Logout
        try {
          await guestSession.clearSession();
        } catch (_) {}
        if (context.mounted) {
          pushAndRemoveAllRoute(AppRoute.guestLogin, context);
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

    final bool isPhone = ScreenSize.isPhone(context);
    final bool shouldBeExpanded = isPhone ? _isExpanded : _isExpanded;

    final items = <NavItemData>[
      const NavItemData(
        label: 'Event Details',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
      ),
      const NavItemData(
        label: 'Demographics',
        icon: Icons.question_answer_outlined,
        selectedIcon: Icons.question_answer,
      ),
      const NavItemData(
        label: 'Menu',
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu,
      ),
      const NavItemData(
        label: 'Feed',
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
      ),
      const NavItemData(
        label: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
      ),
    ];

    // Get event name
    final eventName = guestSession.event.value?.name ?? 'Event';

    final sidebarWidget = SlideTransition(
      position: _sidebarSlide,
      child: FadeTransition(
        opacity: _sidebarFade,
        child: Sidebar(
          selectedIndex: selectedIndex,
          items: items,
          onTap: (i) => _onTap(context, i),
          isExpanded: shouldBeExpanded,
          organisationName: eventName,
          organisationPhotoUrl: guestSession.event.value?.coverImageUrl,
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

    if (isPhone) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: _isExpanded ? 0 : 72.0),
            child: contentWidget,
          ),
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
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: sidebarWidget,
          ),
        ],
      );
    }

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
