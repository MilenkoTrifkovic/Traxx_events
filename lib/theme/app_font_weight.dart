import 'package:flutter/material.dart';
import 'package:traxx_wepapp/utils/enums/figma_font_weight.dart';

/// Font weight utility class that maps Figma font weight specifications
/// to Flutter's FontWeight values for consistent typography
class AppFontWeight {
  /// Returns FontWeight.w100 (Thin)
  static FontWeight get thin => FontWeight.w100;

  /// Returns FontWeight.w200 (Extra Light)
  static FontWeight get extraLight => FontWeight.w200;

  /// Returns FontWeight.w300 (Light)
  static FontWeight get light => FontWeight.w300;

  /// Returns FontWeight.w400 (Regular/Normal)
  static FontWeight get regular => FontWeight.w400;

  /// Returns FontWeight.w500 (Medium)
  static FontWeight get medium => FontWeight.w500;

  /// Returns FontWeight.w600 (Semi Bold)
  static FontWeight get semiBold => FontWeight.w600;

  /// Returns FontWeight.w700 (Bold)
  static FontWeight get bold => FontWeight.w700;

  /// Returns FontWeight.w800 (Extra Bold)
  static FontWeight get extraBold => FontWeight.w800;

  /// Returns FontWeight.w900 (Black)
  static FontWeight get black => FontWeight.w900;

  /// Maps FigmaFontWeight enum to Flutter FontWeight
  ///
  /// Example:
  /// ```dart
  /// final weight = AppFontWeight.fromFigma(FigmaFontWeight.regular);
  /// // Returns FontWeight.w400
  /// ```
  static FontWeight fromFigma(FigmaFontWeight figmaWeight) {
    switch (figmaWeight) {
      case FigmaFontWeight.thin:
        return thin;
      case FigmaFontWeight.extraLight:
        return extraLight;
      case FigmaFontWeight.light:
        return light;
      case FigmaFontWeight.regular:
        return regular;
      case FigmaFontWeight.medium:
        return medium;
      case FigmaFontWeight.semiBold:
        return semiBold;
      case FigmaFontWeight.bold:
        return bold;
      case FigmaFontWeight.extraBold:
        return extraBold;
      case FigmaFontWeight.black:
        return black;
    }
  }
}
