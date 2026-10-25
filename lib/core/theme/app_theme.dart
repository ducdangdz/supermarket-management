import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A single theme for the launcher and all employee, management and API modules.
class AppTheme {
  AppTheme._();
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const success = AppColors.secondary;
  static const warning = AppColors.statusLate;
  static const error = AppColors.statusAbsent;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textHint = AppColors.textMuted;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: AppColors.secondary,
      surface: surface,
      error: error,
      onSurface: textPrimary,
      outline: AppColors.border,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const label = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, height: 1.5, color: textSecondary),
        labelLarge: label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: primary, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: shape,
          textStyle: label,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: shape,
          textStyle: label,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 48),
          shape: shape,
          textStyle: label,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        dividerColor: AppColors.divider,
        labelStyle: label,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }
}
