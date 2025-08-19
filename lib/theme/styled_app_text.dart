import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/constants.dart';

class AppText {
  static Widget styledHeadingMedium(BuildContext context, String text,
      {Color? color,
      String family = Constants.font1,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.normal}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.headingMediumFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.headingLetterSpacing,
          color: color ?? Theme.of(context).colorScheme.primary),
    );
  }

  static Widget styledHeadingLarge(BuildContext context, String text,
      {Color? color,
      String family = Constants.font1,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.normal}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.headingLargeFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.headingLetterSpacing,
          color: color ?? Theme.of(context).colorScheme.primary),
    );
  }

  static Widget styledHeadingSmall(BuildContext context, String text,
      {Color? color,
      String family = Constants.font1,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.normal}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.headingSmallFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.headingLetterSpacing,
          color: color ?? Theme.of(context).colorScheme.primary),
    );
  }

  // Body text styles
  static Widget styledBodyLarge(BuildContext context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.w400}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.bodyLargeFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          height: Constants.bodyLineHeight,
          color: color ?? Theme.of(context).colorScheme.onSurface),
    );
  }

  static Widget styledBodyMedium(BuildContext context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.w400}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.bodyMediumFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          height: Constants.bodyLineHeight,
          color: color ?? Theme.of(context).colorScheme.onSurface),
    );
  }

  static Widget styledBodySmall(BuildContext context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.w400}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.bodySmallFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          height: Constants.bodyLineHeight,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  // Label styles
  static Widget styledLabelLarge(BuildContext context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.w500}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.labelLargeFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.labelLetterSpacing,
          color: color ?? Theme.of(context).colorScheme.primary),
    );
  }

  static Widget styledLabelMedium(BuildContext context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.w500}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.labelMediumFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.labelLetterSpacing,
          color: color ?? Theme.of(context).colorScheme.primary),
    );
  }

  static Widget styledLabelSmall(BuildContext context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.w500}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: Constants.labelSmallFontSize,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.labelLetterSpacing,
          color: color ?? Theme.of(context).colorScheme.primary),
    );
  }
}
