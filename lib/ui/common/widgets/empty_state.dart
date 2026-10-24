import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/anim.dart';
import 'linakan_button.dart';

/// Widget tampilan kosong (empty state) dengan ilustrasi bergradasi
/// dan animasi masuk bertahap.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeSlideIn(
              child: SizedBox(
                width: 96,
                height: 96,
                child: Icon(icon, size: 48, color: AppColors.kColorPrimary),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Text(
                title,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                subtitle,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
                textAlign: TextAlign.center,
              ),
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 230),
                child: LinakanButton(
                  label: ctaLabel!,
                  onPressed: onCtaPressed,
                  compact: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
