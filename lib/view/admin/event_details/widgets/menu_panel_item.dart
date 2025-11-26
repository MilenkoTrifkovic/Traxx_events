import 'package:flutter/material.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class MenuPanelItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final double itemWidth;

  const MenuPanelItem({
    super.key,
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.onTap,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return _MenuPanelItemInteractive(
      title: title,
      icon: icon,
      buttonText: buttonText,
      onTap: onTap,
      itemWidth: itemWidth,
    );
  }
}

class _MenuPanelItemInteractive extends StatefulWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final double itemWidth;

  const _MenuPanelItemInteractive({
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.onTap,
    required this.itemWidth,
  });

  @override
  State<_MenuPanelItemInteractive> createState() =>
      _MenuPanelItemInteractiveState();
}

class _MenuPanelItemInteractiveState extends State<_MenuPanelItemInteractive> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        width: widget.itemWidth,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primaryAccent
                    : AppColors.borderMenuTiles,
                width: 2,
              ),
              color: _isHovered ? AppColors.fofofo : AppColors.surfaceCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.styledBodyLarge(
                      context,
                      widget.title.capitalizeString(),
                      textAlign: TextAlign.center,
                      color: AppColors.primary,
                      weight: AppFontWeight.semiBold,
                    ),
                    Expanded(child: SizedBox.expand()),
                    Icon(
                      widget.icon,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    Expanded(child: SizedBox.expand()),
                    AppText.styledBodyMedium(
                      context,
                      widget.buttonText,
                      color: AppColors.primaryAccent,
                      weight: AppFontWeight.semiBold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
