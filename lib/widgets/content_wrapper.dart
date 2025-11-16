import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class ContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;
  final Color? contentColor;
  final BoxShadow? shadow;

  const ContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1440,
    this.alignment = Alignment.center,
    this.contentColor,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool needsPadding = constraints.maxWidth > maxWidth;
        final double effectiveMaxWidth =
            constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;

        return Container(
          alignment: alignment,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: effectiveMaxWidth,
            ),
            decoration: BoxDecoration(
              color: contentColor ?? AppColors.surface(context),
              boxShadow: [
                shadow ??
                    BoxShadow(
                      color: AppColors.shadow(context).withAlpha(50),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
              ],
            ),
            // child: Padding(
            //   padding: needsPadding
            //       ? AppPadding.horizontal(context, paddingType: Sizes.md)
            //       : EdgeInsets.zero,
            //   child: child,
            // ),
            child: child,
          ),
        );
      },
    );
  }
}
