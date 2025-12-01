import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // 🔥 PURE WHITE EVERYWHERE
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seedColor),
        fontFamily: 'Poppins', // 🔥 GLOBAL FONT = POPPINS
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
            fontFamily: 'Poppins',
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.only(left: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: AppColors.borderSubtle,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: AppColors.primaryAccent,
              width: 1.6,
            ),
          ),
          constraints: const BoxConstraints(
            minHeight: 44,
            maxHeight: 44,
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryAccent,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.secondary,
          ),
        ),
      );
}
