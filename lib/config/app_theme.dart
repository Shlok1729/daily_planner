import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_planner/constants/app_colors.dart';

/// Central theme configuration for the Daily Planner app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Use system fonts as fallback if custom fonts fail to load
  static TextTheme _getTextTheme({bool isDark = false}) {
    try {
      return GoogleFonts.poppinsTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      );
    } catch (e) {
      // Fallback to default text theme if Google Fonts fails
      return isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    }
  }

  /// Light theme configuration
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    fontFamily: 'Poppins', // Use custom font as primary
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.accentLight,
      surface: AppColors.cardLight,
      background: AppColors.backgroundLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onBackground: AppColors.textPrimaryLight,
      error: AppColors.errorLight,
      onError: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    textTheme: _getTextTheme(isDark: false).copyWith(
      displayLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 16,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 12,
        fontFamily: 'Poppins',
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: BorderSide(color: AppColors.primaryLight, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondaryLight.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondaryLight.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorLight, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorLight, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardLight,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? AppColors.primaryLight
            : AppColors.textSecondaryLight;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? AppColors.primaryLight.withOpacity(0.5)
            : AppColors.textSecondaryLight.withOpacity(0.3);
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    iconTheme: IconThemeData(
      color: AppColors.textPrimaryLight,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.textSecondaryLight.withOpacity(0.2),
      thickness: 1,
    ),
  );

  /// Dark theme configuration
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    fontFamily: 'Poppins', // Use custom font as primary
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.accentDark,
      surface: AppColors.cardDark,
      background: AppColors.backgroundDark,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.textPrimaryDark,
      onBackground: AppColors.textPrimaryDark,
      error: AppColors.errorDark,
      onError: Colors.black,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    textTheme: _getTextTheme(isDark: true).copyWith(
      displayLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 16,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 12,
        fontFamily: 'Poppins',
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: BorderSide(color: AppColors.primaryDark, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondaryDark.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondaryDark.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorDark, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorDark, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardDark,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? AppColors.primaryDark
            : AppColors.textSecondaryDark;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? AppColors.primaryDark.withOpacity(0.5)
            : AppColors.textSecondaryDark.withOpacity(0.3);
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardDark,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.black,
      elevation: 6,
    ),
    iconTheme: IconThemeData(
      color: AppColors.textPrimaryDark,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.textSecondaryDark.withOpacity(0.2),
      thickness: 1,
    ),
  );

  /// Get appropriate theme based on brightness
  static ThemeData getTheme(bool isDark) {
    return isDark ? darkTheme : lightTheme;
  }
}