import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';

const double kNavCollapseWidth = 900;

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final Widget content;

  /// If null = full width
  final double? maxContentWidth;

  /// Mobile drawer support
  final GlobalKey<ScaffoldState>? drawerScaffoldKey;

  /// Optional overrides
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppBarCustom({
    super.key,
    required this.content,
    this.maxContentWidth = Constants.maxContentWidth,
    this.drawerScaffoldKey,
    this.backgroundColor,
    this.foregroundColor,
  });

  static const double _barHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < kNavCollapseWidth;

    // ✅ Match Sidebar color by default
    final bg = backgroundColor ?? AppColors.primary;

    // ✅ On dark header, default foreground should be white
    final fg = foregroundColor ?? Colors.white;

    Widget body = content;

    if (maxContentWidth != null) {
      body = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth!),
          child: body,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.10),
              width: 1,
            ),
          ),

          // ✅ Proper shadow without adding layout height (removes the gap)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isMobile ? 10 : 14,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu),
                  color: fg,
                  onPressed: () =>
                      drawerScaffoldKey?.currentState?.openDrawer(),
                ),
              Expanded(
                child: IconTheme(
                  data: IconThemeData(color: fg),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: fg),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);
}
