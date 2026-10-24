import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_surfaces.dart';

/// Token desain bersama. Seluruh peran tipografi menggunakan Poppins.
class AppTokens {
  AppTokens._();

  // --- Palet bernama ---
  static const Color bg = AppColors.kColorBackground;
  static const Color surface = AppColors.kColorSurface;
  static const Color card = AppColors.kColorSurfaceSoft;
  static const Color ink = AppColors.kColorText;
  static const Color inkMuted = AppColors.kColorMuted;
  static const Color border = AppColors.kColorBorder;
  static const Color brand = AppColors.kColorPrimary;
  static const Color accent = AppColors.kColorAccent;
  static const Color success = AppColors.kColorSuccess;
  static const Color danger = AppColors.kColorDanger;

  // --- Spacing scale (8-grid) ---
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // --- BorderRadius ---
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(14),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(26),
  );
  static const BorderRadius stampRadius = BorderRadius.all(
    Radius.circular(200),
  );

  // --- Shadows ---
  static List<BoxShadow> cardShadow = AppSurfaces.raisedShadow;

  // --- Typografi (via GoogleFonts) ---
  static final TextStyle display = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
    color: ink,
  );

  static final TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    color: ink,
  );

  static final TextStyle body = GoogleFonts.poppins();
  static final TextStyle data = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: inkMuted,
  );

  static final TextStyle sectionLabel = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: inkMuted,
  );

  static final TextStyle stamp = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: surface,
  );
}
