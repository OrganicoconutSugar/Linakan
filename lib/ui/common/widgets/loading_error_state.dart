import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Body yang menampilkan indikator loading, banner error (dengan tombol
/// coba lagi), atau konten dari [contentBuilder] sesuai kondisi provider.
class LoadingErrorState extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final WidgetBuilder contentBuilder;

  const LoadingErrorState({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsLight.warningCircle,
                  color: AppColors.kColorDanger, size: 48),
              const SizedBox(height: 12),
              Text(error!,
                  style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kColorPrimary,
                  foregroundColor: AppColors.kColorOnPrimary,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    return contentBuilder(context);
  }
}
