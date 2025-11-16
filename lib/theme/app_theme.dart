import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seedColor),
        fontFamily: 'Inter',
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all<Size>(
              const Size(double.infinity, 48),
            ),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            backgroundColor:
                WidgetStateProperty.all<Color>(AppColors.primaryAccent),
            foregroundColor: WidgetStateProperty.all<Color>(AppColors.white),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          // border: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(8),
          // ),
          // Content padding for height and left padding
          contentPadding: EdgeInsets.only(left: 16),

          // Normal border (unfocused)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Colors.black,
              width: 1,
            ),
          ),

          // Enabled border (normal state)
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.borderSubtle,
            ),
          ),

          // Focused border (when user taps on input)
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.primaryAccent,
            ),
          ),

          // Error border

          // Constraints for consistent height (44px)
          constraints: BoxConstraints(
            minHeight: 44,
            maxHeight: 44,
          ),
        ),
        textTheme: TextTheme(
          // Changed because of Sign in to Trax Events
          headlineSmall: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700, // Medium
            color: AppColors.primary,
          ),
          // Changed because of Sign in to Trax Events
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryAccent,
          ),
          // Changed because of Sign in to Trax Events
          bodySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.secondary,
          ),
        ),
      );
}
