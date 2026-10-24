import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Placeholder peta untuk menampilkan lokasi pengambilan.
/// Tidak menggunakan API peta nyata.
class MapPlaceholder extends StatelessWidget {
  final String address;
  final double height;

  const MapPlaceholder({
    super.key,
    required this.address,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kColorBorder,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            PhosphorIconsLight.mapPin,
            size: 36,
            color: AppColors.kColorPrimary,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              address,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lokasi Pengambilan (Peta Demo)',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
