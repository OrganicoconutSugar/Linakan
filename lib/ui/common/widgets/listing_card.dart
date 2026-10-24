import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/anim.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/match_result_model.dart';
import 'linakan_badge.dart';
import 'linakan_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Kartu listing limbah pangan — tekstur gelap pada gambar, chip harga
/// mengambang, badge kategori & Instant Match, serta efek tekan.
class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final MatchResultModel? matchResult;
  final VoidCallback? onDetailPressed;
  final bool showHero;

  const ListingCard({
    super.key,
    required this.listing,
    this.matchResult,
    this.onDetailPressed,
    this.showHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final pressable = onDetailPressed != null;
    final card = _buildCard(context);

    if (!pressable) return card;
    return PressableScale(onTap: onDetailPressed, child: card);
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      color: AppColors.kColorSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: AppColors.kColorSurface,
          width: 1.3,
        ),
      ),
      elevation: 3,
      shadowColor: AppColors.kColorShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildImage(context),
          ),
          // Info badge
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    LinakanBadge(
                      label: listing.category.name,
                      color: AppColors.kColorPrimarySoft,
                      textColor: AppColors.kColorPrimary,
                    ),
                    if (matchResult?.isInstantMatch == true)
                      const LinakanBadge(
                        label: 'Instant Match',
                        color: AppColors.kColorLime,
                        textColor: AppColors.kColorOnPrimary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listing.wasteName,
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${listing.weight.toStringAsFixed(1)} kg',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.kColorMuted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${formatRupiah(listing.pricePerKg)}/kg',
                        style: AppTextStyles.price.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinakanButton(
                  label: 'Lihat Detail',
                  onPressed: onDetailPressed,
                  icon: PhosphorIconsLight.arrowUpRight,
                  compact: true,
                  variant: LinakanButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final image = listing.imageUrl != null && listing.imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: listing.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            placeholder: (context, __) => const ShimmerBox(height: 200),
            errorWidget: (_, __, ___) => _imageFallback(),
          )
        : _imageFallback();

    return Stack(
      children: [
        image,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 72,
            color: AppColors.kColorText.withAlpha(70),
          ),
        ),
        if (matchResult != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: _InstantScoreChip(score: matchResult!.score),
          ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.kColorBorder,
      child: const Center(
        child: Icon(PhosphorIconsLight.imageBroken,
            color: AppColors.kColorMuted, size: 40),
      ),
    );
  }
}

/// Chip skor kecocokan melingkar (untuk hero image).
class _InstantScoreChip extends StatelessWidget {
  final int score;
  const _InstantScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final isHigh = score >= 85;
    final bg = isHigh ? AppColors.kColorSuccessBg : AppColors.kColorWarningBg;
    final fg = isHigh ? AppColors.kColorSuccess : AppColors.kColorWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withAlpha(90)),
      ),
      child: Row(
        children: [
          Text('$score%',
              style: AppTextStyles.badge.copyWith(color: fg, fontSize: 11)),
          const SizedBox(width: 4),
          Icon(PhosphorIconsLight.sparkle, size: 12, color: fg),
        ],
      ),
    );
  }
}
