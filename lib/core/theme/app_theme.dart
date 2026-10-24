import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Skala radius terpadu LINAKAN.
class AppRadius {
  AppRadius._();

  static const double card = 24.0;
  static const double tile = 20.0;
  static const double button = 17.0;
  static const double field = 17.0;
  static const double chip = 999.0;
  static const double image = 20.0;

  static final BorderRadius cardBorder = BorderRadius.circular(card);
  static final BorderRadius tileBorder = BorderRadius.circular(tile);
  static final BorderRadius buttonBorder = BorderRadius.circular(button);
  static final BorderRadius fieldBorder = BorderRadius.circular(field);
  static final BorderRadius chipBorder = BorderRadius.circular(chip);
}

/// Token durasi dan kurva animasi.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 560);
  static const Duration counter = Duration(milliseconds: 800);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.easeOutBack;
}

/// Pembuat tema utama aplikasi.
ThemeData buildAppTheme() {
  final baseText = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.poppins().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.kColorPrimary,
      primary: AppColors.kColorPrimary,
      secondary: AppColors.kColorAccent,
      surface: AppColors.kColorSurface,
      error: AppColors.kColorDanger,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.kColorBackground,
    textTheme: baseText.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.kColorText,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.kColorText,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.kColorText,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.kColorText,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.kColorText,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.kColorText,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.kColorTextSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.kColorBackground,
      foregroundColor: AppColors.kColorText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: AppColors.kColorSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: const BorderSide(
          color: AppColors.kColorSurface,
          width: 1.2,
        ),
      ),
      elevation: 2,
      shadowColor: AppColors.kColorShadow,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kColorPrimary,
        foregroundColor: AppColors.kColorOnPrimary,
        elevation: 2,
        shadowColor: AppColors.kColorShadow,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.kColorPrimary,
        backgroundColor: AppColors.kColorSurface,
        side: const BorderSide(color: AppColors.kColorBorderStrong),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.kColorSurface,
      modalBackgroundColor: AppColors.kColorSurface,
      elevation: 4,
      shadowColor: AppColors.kColorShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.kColorBorder,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.kColorSurfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorBorderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorBorderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide:
            const BorderSide(color: AppColors.kColorPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorDanger, width: 1.8),
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.kColorBorder),
      ),
      backgroundColor: AppColors.kColorSurface,
      selectedColor: AppColors.kColorPrimarySoft,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
