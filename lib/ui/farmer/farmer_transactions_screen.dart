import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/seller_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/transaction_provider.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/linakan_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

/// Layar daftar transaksi milik peternak.
class FarmerTransactionsScreen extends StatefulWidget {
  const FarmerTransactionsScreen({super.key});

  @override
  State<FarmerTransactionsScreen> createState() =>
      _FarmerTransactionsScreenState();
}

class _FarmerTransactionsScreenState extends State<FarmerTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<ListingProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final currentUserId = authProvider.currentUserId ?? '';

    final myTransactions = transactionProvider
        .getMyTransactions(currentUserId)
        .where((t) => t.farmerId == currentUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Transaksi Saya'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsLight.arrowLeft),
          tooltip: 'Kembali ke Dasbor',
          onPressed: () => context.go('/farmer/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final txProvider = context.read<TransactionProvider>();
          final listingProvider = context.read<ListingProvider>();
          await txProvider.loadTransactions();
          await listingProvider.loadAll();
        },
        child: myTransactions.isEmpty
            ? ListView(
                children: const [
                  EmptyState(
                    icon: PhosphorIconsLight.receipt,
                    title: 'Belum ada transaksi.',
                    subtitle: 'Pembelian limbah Anda akan muncul di sini.',
                  ),
                ],
              )
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: myTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _TransactionItem(
                    transaction: myTransactions[index],
                  );
                },
              ),
      ),
    );
  }
}

class _TransactionItem extends StatefulWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem> {
  bool _isExpanded = false;
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final sellerName =
        context.read<SellerRepository>().getById(tx.sellerId)?.name ??
            tx.sellerId;
    final pickupAddress = context
            .read<ListingProvider>()
            .listings
            .where((l) => l.id == tx.listingId)
            .firstOrNull
            ?.pickupAddress ??
        '-';

    final isReserved = tx.status == 'confirmed';

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: AppSurfaces.ivory,
          boxShadow: AppSurfaces.raisedShadow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kColorBorder),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIconsLight.receipt,
                    color: _statusColor(tx.status),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.wasteName, style: AppTextStyles.heading3),
                        const SizedBox(height: 2),
                        Text(
                          'Seller: $sellerName',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.kColorMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tx.listingWeight.toStringAsFixed(1)} kg · ${formatRupiah(tx.farmerPays)}',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _TxStatusBadge(status: tx.status),
                            const SizedBox(width: 8),
                            Text(formatDate(tx.createdAt),
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? PhosphorIconsLight.caretUp
                        : PhosphorIconsLight.caretDown,
                    color: AppColors.kColorMuted,
                  ),
                ],
              ),
            ),
            if (_isExpanded) ...[
              const Divider(height: 1, color: AppColors.kColorBorder),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                        label: 'Subtotal', value: formatRupiah(tx.totalPrice)),
                    const SizedBox(height: 6),
                    _DetailRow(
                      label:
                          'Biaya Layanan LINAKAN (${(AppConstants.kPlatformFeeRate * 100).toInt()}%)',
                      value: formatRupiah(tx.platformFee),
                    ),
                    const Divider(height: 16, color: AppColors.kColorBorder),
                    _DetailRow(
                      label: 'Total Dibayar',
                      value: formatRupiah(tx.farmerPays),
                      labelStyle: AppTextStyles.heading3,
                      valueStyle: AppTextStyles.price,
                    ),
                    const SizedBox(height: 12),
                    const Text('Lokasi Pengambilan',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(pickupAddress, style: AppTextStyles.body),
                    if (isReserved) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _completing
                              ? null
                              : () => _completeTransaction(tx.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kColorSuccess,
                            foregroundColor: AppColors.kColorOnPrimary,
                            disabledBackgroundColor:
                                AppColors.kColorMuted.withAlpha(80),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.buttonBorder,
                            ),
                          ),
                          child: _completing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.kColorOnPrimary,
                                  ),
                                )
                              : const Text('Selesaikan Transaksi'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeTransaction(String transactionId) async {
    setState(() => _completing = true);
    await context
        .read<TransactionProvider>()
        .completeTransaction(transactionId);
    if (!mounted) return;
    setState(() => _completing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi ditandai selesai.'),
        backgroundColor: AppColors.kColorSuccess,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.kColorSuccess;
      case 'confirmed':
        return AppColors.kColorPrimaryLight;
      case 'cancelled':
        return AppColors.kColorDanger;
      default:
        return AppColors.kColorAccent;
    }
  }
}

class _TxStatusBadge extends StatelessWidget {
  final String status;

  const _TxStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'completed':
        bg = AppColors.kColorSuccess;
        fg = AppColors.kColorOnPrimary;
        label = 'Selesai';
        break;
      case 'confirmed':
        bg = AppColors.kColorPrimaryLight;
        fg = AppColors.kColorOnPrimary;
        label = 'Dipesan';
        break;
      case 'cancelled':
        bg = AppColors.kColorDanger;
        fg = AppColors.kColorOnPrimary;
        label = 'Dibatalkan';
        break;
      default:
        bg = AppColors.kColorWarning;
        fg = AppColors.kColorText;
        label = 'Menunggu';
    }
    return LinakanBadge(label: label, color: bg, textColor: fg);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? AppTextStyles.body),
        Text(
          value,
          style: valueStyle ??
              AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
