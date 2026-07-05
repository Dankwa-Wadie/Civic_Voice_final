import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CivicVoice design token system — dark mode admin dashboard theme.
class AppTheme {
  AppTheme._();

  // ── Color Palette ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryLight = Color(0xFF4A9EF8);
  static const Color primaryDark = Color(0xFF0D47A1);

  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF4285F4);

  static const Color surface = Color(0xFF1E2028);
  static const Color surfaceVariant = Color(0xFF252830);
  static const Color surfaceElevated = Color(0xFF2C2F3A);
  static const Color background = Color(0xFF13151A);
  static const Color divider = Color(0xFF2E3140);

  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFFE8EAED);
  static const Color onSurfaceMuted = Color(0xFF9AA0B4);
  static const Color onSurfaceDim = Color(0xFF5F6475);

  // ── Status Colors ──────────────────────────────────────────────────────────
  static const Color statusSubmitted = Color(0xFFFBBC04);
  static const Color statusReviewed = Color(0xFF4285F4);
  static const Color statusDispatched = Color(0xFFFF6D00);
  static const Color statusResolved = Color(0xFF34A853);

  // ── Category Colors ────────────────────────────────────────────────────────
  static const Color categoryPothole = Color(0xFFEA4335);
  static const Color categoryWaterLeak = Color(0xFF4285F4);
  static const Color categoryLightFailure = Color(0xFFFBBC04);
  static const Color categoryDrainage = Color(0xFF9C27B0);
  static const Color categoryRoadDamage = Color(0xFFFF6D00);

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ── Border Radius ──────────────────────────────────────────────────────────
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusButton = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusChip = BorderRadius.all(Radius.circular(20));

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w700, color: onSurface,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w700, color: onSurface,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600, color: onSurface,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400, color: onSurfaceMuted,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceDim,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: onSurface,
      ),
    );

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: success,
        tertiary: warning,
        error: error,
        surface: surface,
        onPrimary: onPrimary,
        onSurface: onSurface,
        onSecondary: onPrimary,
        outline: divider,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusCard),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
          padding: const EdgeInsets.symmetric(
            horizontal: md, vertical: sm + 2,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm + 2),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyLarge,
        contentPadding: const EdgeInsets.symmetric(horizontal: md, vertical: sm + 4),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: onSurfaceDim),
        selectedLabelTextStyle: TextStyle(color: primary, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: onSurfaceDim, fontSize: 12),
        indicatorColor: Color(0x221A73E8),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary.withOpacity(0.2),
        labelStyle: textTheme.bodySmall,
        side: const BorderSide(color: divider),
        shape: const RoundedRectangleBorder(borderRadius: radiusChip),
        padding: const EdgeInsets.symmetric(horizontal: sm),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: textTheme.bodyLarge,
        actionTextColor: primary,
        shape: const RoundedRectangleBorder(borderRadius: radiusButton),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceElevated),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusButton),
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF202124),
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF202124),
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF202124),
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF202124),
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF202124),
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF202124),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF202124),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF5F6368),
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF80868B),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF202124),
      ),
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: success,
        tertiary: warning,
        error: error,
        surface: Colors.white,
        onPrimary: onPrimary,
        onSurface: Color(0xFF202124),
        onSecondary: onPrimary,
        outline: Color(0xFFDADCE0),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: Color(0xFF202124)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusCard),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
          padding: const EdgeInsets.symmetric(
            horizontal: md, vertical: sm + 2,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm + 2),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F4),
        border: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusButton,
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyLarge,
        contentPadding: const EdgeInsets.symmetric(horizontal: md, vertical: sm + 4),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFDADCE0), thickness: 1),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: Color(0xFF80868B)),
        selectedLabelTextStyle: TextStyle(color: primary, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFF80868B), fontSize: 12),
        indicatorColor: Color(0x221A73E8),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F3F4),
        selectedColor: primary.withOpacity(0.2),
        labelStyle: textTheme.bodySmall,
        side: const BorderSide(color: Color(0xFFDADCE0)),
        shape: const RoundedRectangleBorder(borderRadius: radiusChip),
        padding: const EdgeInsets.symmetric(horizontal: sm),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFE8EAED),
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: const Color(0xFF202124)),
        actionTextColor: primary,
        shape: const RoundedRectangleBorder(borderRadius: radiusButton),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFFF8F9FA)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusButton),
          ),
        ),
      ),
    );
  }

  // ── Helper: status color ───────────────────────────────────────────────────
  static Color statusColor(String status) => switch (status.toLowerCase()) {
    'submitted' => statusSubmitted,
    'reviewed' => statusReviewed,
    'dispatched' => statusDispatched,
    'resolved' => statusResolved,
    _ => onSurfaceDim,
  };

  // ── Helper: category color ─────────────────────────────────────────────────
  static Color categoryColor(String category) => switch (category.toLowerCase()) {
    'pothole' => categoryPothole,
    'waterleak' => categoryWaterLeak,
    'structurallightfailure' => categoryLightFailure,
    'drainageblockage' => categoryDrainage,
    'roaddamage' => categoryRoadDamage,
    _ => onSurfaceDim,
  };
}
