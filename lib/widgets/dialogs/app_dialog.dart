import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class AppDialog extends StatelessWidget {
  final Widget? header;
  final Widget content;
  final Widget? footer;

  const AppDialog({
    super.key,
    this.header,
    required this.content,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppBorderRadius.radius(context, size: Sizes.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) header!,
              Expanded(child: content),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}
