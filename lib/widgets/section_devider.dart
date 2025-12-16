import 'package:flutter/material.dart';

/// A reusable section divider that can be customized or used with default styling.
///
/// Parameters:
/// - [thickness] - The thickness of the divider line (default: 1.0)
/// - [color] - The color of the divider (defaults to outline color from theme)
/// - [indent] - The amount of empty space to the leading edge of the divider (default: 0.0)
/// - [endIndent] - The amount of empty space to the trailing edge of the divider (default: 0.0)
/// - [height] - The divider's height extent (default: 16.0)
class SectionDivider extends StatelessWidget {
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;
  final double? height;

  const SectionDivider({
    super.key,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      //Default values if called without parameters
      thickness: thickness ?? 0.0,
      color: color ?? Theme.of(context).dividerColor,
      indent: indent ?? 0.0,
      endIndent: endIndent ?? 0.0,
      height: height ?? 16.0,
    );
  }
}
