import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';

class AppText {
  static Widget styledMetaSmall(BuildContext? context, String text,
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
          fontSize: 12,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          color: color ?? AppColors.white),
    );
  }

  static Widget styledHeadingMedium(BuildContext? context, String text,
      {Color? color,
      String family = Constants.font2,
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
          fontWeight: FontWeight.w600,
          height: 1.4,
          fontStyle: style,
          letterSpacing: Constants.headingLetterSpacing,
          color: color ?? AppColors.white),
    );
  }

  static Widget styledHeadingLarge(BuildContext? context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      FontWeight weight = FontWeight.bold}) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      style: TextStyle(
          fontFamily: family,
          fontSize: 32,
          decoration: decoration,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: Constants.headingLetterSpacing,
          color: color ?? Colors.black),
    );
  }

  static Widget styledHeadingSmall(BuildContext? context, String text,
      {Color? color,
      String family = Constants.font2,
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
          color: color ?? Colors.black),
    );
  }

  // Body text styles
  static Widget styledBodyLarge(BuildContext? context, String text,
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
          color: color ?? AppColors.black),
    );
  }

  static Widget styledBodyMedium(BuildContext? context, String text,
      {Color? color,
      String family = Constants.font2,
      TextDecoration? decoration,
      TextOverflow? overflow,
      FontStyle? style,
      int? maxLines,
      TextAlign? textAlign,
      bool isSelectable = false,
      FontWeight weight = FontWeight.w400}) {
    final TextStyle textStyle = TextStyle(
        fontFamily: family,
        fontSize: Constants.bodyMediumFontSize,
        decoration: decoration,
        fontWeight: weight,
        fontStyle: style,
        height: Constants.bodyLineHeight,
        color: color ?? AppColors.black);

    return isSelectable
        ? SelectableText(
            text,
            maxLines: maxLines,
            textAlign: textAlign,
            style: textStyle,
          )
        : Text(
            text,
            overflow: overflow,
            maxLines: maxLines,
            textAlign: textAlign,
            style: textStyle,
          );
  }

  static Widget styledBodySmall(BuildContext? context, String text,
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
          color: color ?? AppColors.black),
    );
  }

  // Label styles
  static Widget styledLabelLarge(BuildContext? context, String text,
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
          color: color ?? Colors.black),
    );
  }

  static Widget styledLabelMedium(BuildContext? context, String text,
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
          color: color ?? Colors.black),
    );
  }

  static Widget styledLabelSmall(BuildContext? context, String text,
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
          color: color ?? Colors.black),
    );
  }
}
