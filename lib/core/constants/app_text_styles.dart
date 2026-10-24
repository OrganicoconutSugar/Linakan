import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gaya teks LINAKAN — semua menggunakan Poppins (via google_fonts).
/// Token nama tetap sama dengan versi lama agar kode existing tidak perlu ubah.
class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Poppins';

  // --- Display (hero / splashes) ---
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.kColorText,
    letterSpacing: -0.8,
    height: 1.05,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.kColorText,
    letterSpacing: -0.5,
    height: 1.1,
  );

  // --- Headings ---
  static const TextStyle heading1 = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.kColorText,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.kColorText,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.kColorText,
    height: 1.35,
  );

  // --- Body ---
  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.kColorText,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.kColorText,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.kColorTextSecondary,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.kColorMuted,
    height: 1.4,
  );

  // --- Special ---
  static const TextStyle price = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.kColorPrimary,
    letterSpacing: -0.2,
    height: 1.15,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  // --- Logo (SuperBold) ---
  static const TextStyle logoTitle = TextStyle(
    fontFamily: _font,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.kColorPrimary,
    letterSpacing: 1.0,
    height: 1.05,
  );

  static const TextStyle logoSubtitle = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.kColorMuted,
    fontStyle: FontStyle.italic,
    height: 1.4,
  );
}
