import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Permukaan off-white dan bayangan tunggal dengan opacity sekitar 5%.
class AppSurfaces {
  AppSurfaces._();

  static const Color ivory = AppColors.kColorSurface;

  static const Color inset = AppColors.kColorSurfaceCard;
  static const Color glass = Color(0xE6F8FAFB);

  static const List<BoxShadow> raisedShadow = [
    BoxShadow(
        color: AppColors.kColorShadow, blurRadius: 12, offset: Offset(0, 5)),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
        color: AppColors.kColorShadow, blurRadius: 16, offset: Offset(0, 7)),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
        color: AppColors.kColorShadow, blurRadius: 12, offset: Offset(0, 5)),
  ];
}
