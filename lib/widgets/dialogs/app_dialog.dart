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
    // Use Center + ConstrainedBox to avoid intrinsic measurements and give
    // the dialog a sensible maximum width. Content is placed inside a
    // SingleChildScrollView with a bounded max height so children receive
    // finite constraints and don't cause layout exceptions.
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: 488.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppBorderRadius.radius(context, size: Sizes.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) header!,
              // Wrap content in a scrollable area with a bounded max height
              // so long content scrolls instead of forcing unbounded layout.
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: content,
                ),
              ),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}
