import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/waste_category.dart';
import '../../../domain/shelf_life_service.dart';

/// Progress bar masa simpan listing.
/// Intensitas biru membedakan kondisi masa simpan.
class ShelfLifeBar extends StatelessWidget {
  final WasteCategory category;
  final DateTime createdAt;

  ShelfLifeBar({
    super.key,
    required this.category,
    required this.createdAt,
  });

  final ShelfLifeService _shelfLifeService = ShelfLifeService();

  @override
  Widget build(BuildContext context) {
    final progress = _shelfLifeService.getExpiryProgress(category, createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.kColorBorder,
          valueColor: AlwaysStoppedAnimation<Color>(_barColor(progress)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Color _barColor(double progress) {
    if (progress >= 1.0) return AppColors.kColorDanger;
    if (progress > 0.7) return AppColors.kColorWarning;
    return AppColors.kColorSuccess;
  }
}
