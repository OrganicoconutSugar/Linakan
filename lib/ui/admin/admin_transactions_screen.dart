import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../data/repositories/seller_repository.dart';
import '../../providers/transaction_provider.dart';
import '../common/widgets/loading_error_state.dart';
import '../common/widgets/linakan_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Layar transaksi admin — semua transaksi dengan ekspor CSV.
class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  Future<void> _exportCsv(List<TransactionModel> txns) async {
    setState(() => _exporting = true);
    final sellerRepo = context.read<SellerRepository>();
    final farmerRepo = context.read<FarmerRepository>();
    try {
      final rows = txns.map((t) {
        final sellerName = sellerRepo.getById(t.sellerId)?.name ?? t.sellerId;
        final buyerName = farmerRepo.getById(t.farmerId)?.name ?? t.farmerId;
        return [
          t.id,
          sellerName,
          t.wasteName,
          t.listingWeight.toStringAsFixed(1),
          buyerName,
          t.status,
          t.totalPrice.toString(),
          t.platformFee.toString(),
          t.createdAt.toIso8601String(),
        ];
      }).toList();
      await exportCsvToTempFile(
        fileName: 'linakan_transactions.csv',
        header: const [
          'id',
          'seller',
          'waste',
          'weight',
          'buyer',
          'status',
          'totalPrice',
          'platformFee',
          'createdAt'
        ],
        rows: rows,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CSV berhasil diekspor: linakan_transactions.csv\n'
            '(Tersimpan di penyimpanan sementara — fitur bagikan tersedia di versi mendatang)',
          ),
          backgroundColor: AppColors.kColorSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor CSV: $e'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final sellerRepo = context.watch<SellerRepository>();
    final farmerRepo = context.watch<FarmerRepository>();

    final txns = transactionProvider.transactions.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsLight.arrowLeft),
          tooltip: 'Kembali ke Dasbor Admin',
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('Transaksi'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exporting ? null : () => _exportCsv(txns),
        backgroundColor: AppColors.kColorPrimary,
        foregroundColor: AppColors.kColorOnPrimary,
        icon: _exporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.kColorOnPrimary),
              )
            : const Icon(PhosphorIconsLight.download),
        label: const Text('Ekspor CSV'),
      ),
      body: LoadingErrorState(
        isLoading: transactionProvider.isLoading,
        error: transactionProvider.error,
        onRetry: () => context.read<TransactionProvider>().loadTransactions(),
        contentBuilder: (context) {
          if (txns.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada transaksi.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: txns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _TransactionRow(
              txn: txns[index],
              sellerName: sellerRepo.getById(txns[index].sellerId)?.name ??
                  txns[index].sellerId,
              buyerName: farmerRepo.getById(txns[index].farmerId)?.name ??
                  txns[index].farmerId,
            ),
          );
        },
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel txn;
  final String sellerName;
  final String buyerName;
  const _TransactionRow({
    required this.txn,
    required this.sellerName,
    required this.buyerName,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = txn.id.length > 8 ? txn.id.substring(0, 8) : txn.id;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#$shortId',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.kColorMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(txn.wasteName,
                    style: AppTextStyles.body, overflow: TextOverflow.ellipsis),
              ),
              _StatusBadge(status: txn.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Seller: $sellerName · Pembeli: $buyerName',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.kColorMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${txn.listingWeight.toStringAsFixed(1)} kg · ${formatRupiah(txn.totalPrice)}',
                style: AppTextStyles.body,
              ),
              const Spacer(),
              Text(formatDate(txn.createdAt), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

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
