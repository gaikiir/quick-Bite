import 'package:flutter/material.dart';
import 'package:quick_bite/screens/constants/app_colors.dart';

class Styles {
  static ThemeData themeData({
    required bool isDarkTheme,
    required BuildContext context,
  }) {
    return ThemeData(
      useMaterial3: true,
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: isDarkTheme ? AppColors.darkPrimary : AppColors.lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: isDarkTheme
            ? AppColors.darkPrimaryContainer
            : AppColors.lightPrimaryContainer,
        onPrimaryContainer: isDarkTheme ? Colors.white70 : Colors.black87,
        secondary: isDarkTheme ? AppColors.darkPrimary : AppColors.lightPrimary,
        onSecondary: Colors.white,
        error: AppColors.errorColor,
        onError: Colors.white,
        background: isDarkTheme
            ? AppColors.darkBackgroundColor
            : AppColors.lightBackgroundColor,
        onBackground: isDarkTheme
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
        surface: isDarkTheme
            ? AppColors.darkSurfaceColor
            : AppColors.lightSurfaceColor,
        onSurface: isDarkTheme
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
      ),

      // Basic ThemeData
      scaffoldBackgroundColor: isDarkTheme
          ? AppColors.darkScaffoldColor
          : AppColors.lightScaffoldColor,
      cardColor: isDarkTheme
          ? AppColors.darkCardColor
          : AppColors.lightCardColor,
      dividerColor: isDarkTheme
          ? AppColors.darkDividerColor
          : AppColors.lightDividerColor,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkTheme
            ? AppColors.darkCardColor
            : AppColors.lightCardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: isDarkTheme
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontSize: 14,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme
            ? AppColors.darkCardColor
            : AppColors.lightCardColor,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkTheme
                ? AppColors.darkDividerColor
                : AppColors.lightDividerColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkTheme
                ? AppColors.darkDividerColor
                : AppColors.lightDividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkTheme ? AppColors.darkPrimary : AppColors.lightPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorColor, width: 2),
        ),
      ),

      // Card Theme
      // Card Theme
      cardTheme: CardThemeData(
        color: isDarkTheme ? AppColors.darkCardColor : AppColors.lightCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: isDarkTheme
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDarkTheme
              ? AppColors.darkPrimary
              : AppColors.lightPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Dialog Theme
      dialogBackgroundColor: isDarkTheme
          ? AppColors.darkCardColor
          : AppColors.lightCardColor,
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
