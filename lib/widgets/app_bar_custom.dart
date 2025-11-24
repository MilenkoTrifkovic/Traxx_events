import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final Widget content;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppBarCustom({
    super.key,
    required this.content,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor:
            foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false,
        toolbarHeight: 68.0,
        elevation: 0,
        shadowColor: Colors.transparent,
        title: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Constants.maxContentWidth),
            child: Padding(
              padding: AppPadding.vertical(context, paddingType: Sizes.xxs),
              child: content,
            ),
          ),
        ),
        titleSpacing: 0.0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68.0);
}
