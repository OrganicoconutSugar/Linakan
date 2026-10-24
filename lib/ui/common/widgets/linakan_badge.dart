import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Badge kecil LINAKAN dengan warna yang dapat dikustomisasi.
class LinakanBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const LinakanBadge({
    super.key,
    required this.label,
    this.color = AppColors.kColorPrimary,
    this.textColor = AppColors.kColorOnPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kColorSurface.withAlpha(180)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.kColorShadow,
              blurRadius: 5,
              offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: textColor),
      ),
    );
  }
}
