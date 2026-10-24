import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/match_result_model.dart';
import 'listing_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Kartu kecocokan — memperluas ListingCard dengan bilah kompatibilitas
/// yang dianimasikan dan chip skor.
class MatchCard extends StatelessWidget {
  final MatchResultModel matchResult;
  final VoidCallback? onDetailPressed;

  const MatchCard({
    super.key,
    required this.matchResult,
    this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingCard(
          listing: matchResult.listing,
          matchResult: matchResult,
          onDetailPressed: onDetailPressed,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _CompatibilityBar(matchResult: matchResult),
        ),
      ],
    );
  }
}

class _CompatibilityBar extends StatelessWidget {
  final MatchResultModel matchResult;

  const _CompatibilityBar({required this.matchResult});

  @override
  Widget build(BuildContext context) {
    final score = matchResult.score;
    final progress = (score / 100).clamp(0.0, 1.0).toDouble();
    final color = _scoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tingkat Kecocokan', style: AppTextStyles.bodySmall),
            Tooltip(
              message: _breakdown,
              child: Row(
                children: [
                  Text(
                    '$score% cocok',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(PhosphorIconsLight.info,
                      size: 14, color: AppColors.kColorMuted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.kColorBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }

  String get _breakdown {
    return 'Kategori: ${matchResult.categoryScore}% · '
        'Lokasi: ${matchResult.locationScore}% · '
        'Kapasitas: ${matchResult.capacityScore}%';
  }

  Color _scoreColor(int score) {
    if (score >= 85) return AppColors.kColorSuccess;
    if (score >= 60) return AppColors.kColorWarning;
    return AppColors.kColorDanger;
  }
}
