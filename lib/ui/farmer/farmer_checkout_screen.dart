import '../../core/constants/app_surfaces.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/farmer_model.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/seller_model.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../data/repositories/seller_repository.dart';
import '../../domain/pricing_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

/// Layar checkout peternak — ringkasan item, rincian biaya (termasuk biaya
/// layanan LINAKAN 5%), info saldo dompet, dan konfirmasi pembelian.
class FarmerCheckoutScreen extends StatefulWidget {
  final String listingId;

  const FarmerCheckoutScreen({super.key, required this.listingId});

  @override
  State<FarmerCheckoutScreen> createState() => _FarmerCheckoutScreenState();
}

class _FarmerCheckoutScreenState extends State<FarmerCheckoutScreen> {
  final PricingService _pricingService = PricingService();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;
    if (userId == null) return;
    final listingProvider = context.read<ListingProvider>();
    final walletProvider = context.read<WalletProvider>();
    await listingProvider.loadAll();
    await walletProvider.loadBalance(userId, 'farmer');
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();

    final listing = listingProvider.listings
        .where((l) => l.id == widget.listingId)
        .firstOrNull;

    if (listing == null) {
      return Scaffold(
        backgroundColor: AppColors.kColorBackground,
        appBar: AppBar(
          title: const Text('Konfirmasi Pembelian'),
          backgroundColor: AppColors.kColorSurface,
          foregroundColor: AppColors.kColorText,
        ),
        body: const Center(child: Text('Listing tidak ditemukan.')),
      );
    }

    final userId = context.read<AuthProvider>().currentUserId ?? '';
    final farmer = context.read<FarmerRepository>().getById(userId);
    final seller = context.read<SellerRepository>().getById(listing.sellerId);

    if (farmer == null || seller == null) {
      return Scaffold(
        backgroundColor: AppColors.kColorBackground,
        appBar: AppBar(
          title: const Text('Konfirmasi Pembelian'),
          backgroundColor: AppColors.kColorSurface,
          foregroundColor: AppColors.kColorText,
        ),
        body: const Center(child: Text('Data pengguna tidak ditemukan.')),
      );
    }

    final subtotal = listing.finalPrice;
    final breakdown = _pricingService.calculateWithFee(subtotal);
    final platformFee = breakdown.platformFee;
    final total = breakdown.total;
    final feePercent = (AppConstants.kPlatformFeeRate * 100).toInt();

    final balance = farmer.walletBalance;
    final balanceAfter = balance - total;
    final insufficient = balance < total;

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Konfirmasi Pembelian'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Ringkasan item
          _ItemSummary(listing: listing),
          const SizedBox(height: 20),

          // Rincian biaya
          const Text('Rincian Pembayaran', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppSurfaces.ivory,
              boxShadow: AppSurfaces.raisedShadow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kColorBorder),
            ),
            child: Column(
              children: [
                _PriceRow(
                  label: 'Subtotal',
                  value: formatRupiah(subtotal),
                ),
                const SizedBox(height: 10),
                _PriceRow(
                  label: 'Biaya Layanan LINAKAN ($feePercent%)',
                  value: formatRupiah(platformFee),
                ),
                const Divider(height: 20, color: AppColors.kColorBorder),
                _PriceRow(
                  label: 'Total',
                  value: formatRupiah(total),
                  labelStyle: AppTextStyles.heading3,
                  valueStyle: AppTextStyles.price,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info dompet
          const Text('Dompet LINAKAN', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kColorPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Dompet Anda: ${formatRupiah(balance)}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.kColorOnPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saldo setelah bayar: ${formatRupiah(balanceAfter)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.kColorOnPrimary.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),

          if (insufficient) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kColorDanger.withAlpha(16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kColorDanger.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsLight.warning,
                          color: AppColors.kColorDanger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saldo tidak cukup. Silakan top up terlebih dahulu.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.kColorDanger),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/wallet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kColorDanger,
                        foregroundColor: AppColors.kColorOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonBorder,
                        ),
                      ),
                      child: const Text('Top Up Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _buildConfirmBar(
        listing: listing,
        farmer: farmer,
        seller: seller,
        total: total,
        insufficient: insufficient,
      ),
    );
  }

  Widget _buildConfirmBar({
    required ListingModel listing,
    required FarmerModel farmer,
    required SellerModel seller,
    required int total,
    required bool insufficient,
  }) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.kColorSurface,
          border: Border(top: BorderSide(color: AppColors.kColorBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bayar', style: AppTextStyles.body),
                Text(formatRupiah(total), style: AppTextStyles.price),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing
                    ? null
                    : () => _onConfirm(
                          listing: listing,
                          farmer: farmer,
                          seller: seller,
                          insufficient: insufficient,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kColorPrimary,
                  foregroundColor: AppColors.kColorOnPrimary,
                  disabledBackgroundColor: AppColors.kColorMuted.withAlpha(80),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonBorder,
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.kColorOnPrimary,
                        ),
                      )
                    : const Text('Konfirmasi Pembelian'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onConfirm({
    required ListingModel listing,
    required FarmerModel farmer,
    required SellerModel seller,
    required bool insufficient,
  }) async {
    // Saldo tidak cukup — tampilkan peringatan, jangan proses.
    if (insufficient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo tidak cukup. Silakan top up terlebih dahulu.'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
      return;
    }

    // Konfirmasi eksplisit via dialog sebelum memproses.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi & Beli?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listing.wasteName, style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              '${listing.weight.toStringAsFixed(1)} kg · ${formatRupiah(listing.finalPrice)}',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            Text(
                'Total: ${formatRupiah(_pricingService.calculateWithFee(listing.finalPrice).total)}',
                style: AppTextStyles.price),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorPrimary,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _processing = true);

    final transactionProvider = context.read<TransactionProvider>();
    final walletProvider = context.read<WalletProvider>();
    final result = await transactionProvider.confirmTransaction(
      listing: listing,
      farmer: farmer,
      seller: seller,
    );

    // Segarkan saldo dompet & transaksi setelah pembayaran.
    await walletProvider.loadBalance(farmer.id, 'farmer');
    await transactionProvider.loadTransactions();

    if (!mounted) return;
    setState(() => _processing = false);

    if (result.success) {
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Gagal memproses pembelian.'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsLight.checkCircle,
                color: AppColors.kColorSuccess, size: 64),
            SizedBox(height: 16),
            Text('Pembelian Berhasil!', style: AppTextStyles.heading2),
            SizedBox(height: 8),
            Text(
              'Limbah telah dipesan. Penjual akan menghubungi Anda untuk pengambilan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/farmer/transactions');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kColorPrimary,
                foregroundColor: AppColors.kColorOnPrimary,
              ),
              child: const Text('Lihat Transaksi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  final ListingModel listing;

  const _ItemSummary({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: AppRadius.buttonBorder,
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: listing.imageUrl!,
                    height: 64,
                    width: 64,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgFallback(),
                  )
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.wasteName, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  '${listing.weight.toStringAsFixed(1)} kg · ${formatRupiah(listing.pricePerKg)}/kg',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.kColorMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(PhosphorIconsLight.mapPin,
                        size: 14, color: AppColors.kColorMuted),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        listing.pickupAddress,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.kColorMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      height: 64,
      width: 64,
      color: AppColors.kColorBorder,
      child: const Icon(PhosphorIconsLight.image,
          color: AppColors.kColorMuted, size: 24),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _PriceRow({
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
