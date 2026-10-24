import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_text_styles.dart';

/// Kartu saldo LINAKAN Wallet.
class WalletBalanceCard extends StatelessWidget {
  final String formattedBalance;
  final VoidCallback? onTopUp;

  const WalletBalanceCard({
    super.key,
    required this.formattedBalance,
    this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kColorPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kColorPrimaryLight),
        boxShadow: AppSurfaces.buttonShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo LINAKAN Wallet',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.kColorSurface.withAlpha(200),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedBalance,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.kColorSurface,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kColorSurface,
                foregroundColor: AppColors.kColorPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonBorder,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Top Up',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
