import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Menampilkan alur top up simulasi yang dapat dipakai dari dashboard
/// maupun laman dompet.
Future<void> showTopUpSheet(BuildContext context) async {
  int? selectedAmount;
  final customController = TextEditingController();
  var method = 'BCA Transfer';
  final messenger = ScaffoldMessenger.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.kColorSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.kColorBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Top Up Dompet', style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  const Text('Pilih Nominal', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [50000, 100000, 200000, 500000].map((amount) {
                      final isSelected = selectedAmount == amount;
                      return ChoiceChip(
                        label: Text(formatRupiah(amount)),
                        selected: isSelected,
                        onSelected: (_) {
                          setSheetState(() {
                            selectedAmount = isSelected ? null : amount;
                            customController.clear();
                          });
                        },
                        selectedColor: AppColors.kColorPrimary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.kColorOnPrimary
                              : AppColors.kColorText,
                          fontWeight: FontWeight.w600,
                        ),
                        side: const BorderSide(color: AppColors.kColorBorder),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Atau Nominal Lain',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: 'Masukkan nominal',
                      filled: true,
                      fillColor: AppColors.kColorBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.kColorBorder),
                      ),
                    ),
                    onChanged: (_) {
                      if (selectedAmount != null) {
                        setSheetState(() => selectedAmount = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Metode Pembayaran',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['BCA Transfer', 'Mandiri Transfer', 'GoPay']
                        .map((paymentMethod) {
                      final isSelected = method == paymentMethod;
                      return ChoiceChip(
                        label: Text(paymentMethod),
                        selected: isSelected,
                        onSelected: (_) => setSheetState(
                          () => method = paymentMethod,
                        ),
                        selectedColor: AppColors.kColorPrimary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.kColorOnPrimary
                              : AppColors.kColorText,
                          fontWeight: FontWeight.w600,
                        ),
                        side: const BorderSide(color: AppColors.kColorBorder),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Top up ini merupakan simulasi dan tidak memproses pembayaran nyata.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.kColorTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<WalletProvider>(
                      builder: (_, walletProvider, __) {
                        return ElevatedButton(
                          onPressed: walletProvider.loading
                              ? null
                              : () async {
                                  final amount = selectedAmount ??
                                      int.tryParse(
                                        customController.text.trim(),
                                      );
                                  if (amount == null || amount <= 0) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Masukkan nominal yang valid.',
                                        ),
                                        backgroundColor: AppColors.kColorDanger,
                                      ),
                                    );
                                    return;
                                  }

                                  final userId = sheetContext
                                      .read<AuthProvider>()
                                      .currentUserId;
                                  if (userId == null) return;

                                  await walletProvider.topUp(
                                    userId,
                                    amount,
                                    method,
                                  );
                                  if (!sheetContext.mounted) return;

                                  final error = walletProvider.error;
                                  if (error != null) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: AppColors.kColorDanger,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Top up ${formatRupiah(amount)} berhasil.',
                                      ),
                                      backgroundColor: AppColors.kColorSuccess,
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kColorPrimary,
                            foregroundColor: AppColors.kColorOnPrimary,
                            disabledBackgroundColor:
                                AppColors.kColorMuted.withAlpha(80),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            walletProvider.loading
                                ? 'Memproses...'
                                : 'Konfirmasi Top Up',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  customController.dispose();
}
