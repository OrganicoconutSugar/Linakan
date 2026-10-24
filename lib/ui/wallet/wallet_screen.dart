import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/top_up_sheet.dart';
import '../common/widgets/wallet_balance_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Layar dompet LINAKAN — dipakai bersama oleh seller dan farmer.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;
    if (userId == null) return;
    final userType = authProvider.isSeller ? 'seller' : 'farmer';
    final walletProvider = context.read<WalletProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    await walletProvider.loadBalance(userId, userType);
    if (!mounted) return;
    await transactionProvider.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    final isSeller = authProvider.isSeller;
    final currentUserId = authProvider.currentUserId ?? '';

    final history = _buildHistory(transactionProvider, currentUserId, isSeller);
    final feePercent = (AppConstants.kPlatformFeeRate * 100).toInt();

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('LINAKAN Wallet'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(PhosphorIconsLight.caretLeft, size: 22),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(PhosphorIconsLight.caretLeft, size: 22),
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  context.go(auth.isFarmer
                      ? '/farmer/dashboard'
                      : '/seller/dashboard');
                },
              ),
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            WalletBalanceCard(
              formattedBalance: walletProvider.formattedBalance,
              onTopUp: () => showTopUpSheet(context),
            ),
            if (isSeller) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showWithdrawDialog(),
                  icon: const Icon(PhosphorIconsLight.bank, size: 18),
                  label: const Text('Tarik Dana'),
                ),
              ),
            ],
            if (walletProvider.error != null) ...[
              const SizedBox(height: 12),
              Text(
                walletProvider.error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.kColorDanger),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Riwayat Transaksi', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const EmptyState(
                icon: PhosphorIconsLight.receipt,
                title: 'Belum ada riwayat.',
                subtitle: 'Transaksi dompet Anda akan muncul di sini.',
              )
            else
              ...history.map((item) => _HistoryItem(item: item)),
            const SizedBox(height: 24),
            const Divider(color: AppColors.kColorBorder),
            const SizedBox(height: 8),
            Text(
              'LINAKAN memungut biaya layanan sebesar $feePercent% dari nilai '
              'setiap transaksi. Pembayaran bersifat simulasi demo.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<_HistoryEntry> _buildHistory(
    TransactionProvider provider,
    String userId,
    bool isSeller,
  ) {
    final txns = provider
        .getMyTransactions(userId)
        .where((t) => isSeller ? t.sellerId == userId : t.farmerId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return txns.map((t) {
      if (isSeller) {
        return _HistoryEntry(
          isIncoming: true,
          amount: t.sellerReceives,
          description: 'Penjualan ${t.wasteName}',
          date: t.createdAt,
        );
      }
      return _HistoryEntry(
        isIncoming: false,
        amount: t.farmerPays,
        description: 'Pembelian ${t.wasteName}',
        date: t.createdAt,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Withdrawal (seller)
  // ---------------------------------------------------------------------------
  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarik Dana'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: 'Rp ',
            hintText: 'Masukkan nominal',
            filled: true,
            fillColor: AppColors.kColorBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.kColorBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan nominal yang valid.'),
                    backgroundColor: AppColors.kColorDanger,
                  ),
                );
                return;
              }
              final userId = context.read<AuthProvider>().currentUserId;
              if (userId == null) return;
              final walletProvider = context.read<WalletProvider>();
              final messenger = ScaffoldMessenger.of(context);
              await walletProvider.requestWithdrawal(userId, amount);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              final error = walletProvider.error;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Permintaan penarikan diajukan.'),
                  backgroundColor: error != null
                      ? AppColors.kColorDanger
                      : AppColors.kColorSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorPrimary,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Konfirmasi Penarikan'),
          ),
        ],
      ),
    );
  }
}

/// Satu baris riwayat transaksi dompet.
class _HistoryEntry {
  final bool isIncoming; // true = masuk (top up/penjualan), false = keluar
  final int amount;
  final String description;
  final DateTime date;

  const _HistoryEntry({
    required this.isIncoming,
    required this.amount,
    required this.description,
    required this.date,
  });
}

class _HistoryItem extends StatelessWidget {
  final _HistoryEntry item;

  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final color =
        item.isIncoming ? AppColors.kColorSuccess : AppColors.kColorDanger;
    final sign = item.isIncoming ? '+' : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            item.isIncoming
                ? PhosphorIconsLight.arrowDown
                : PhosphorIconsLight.arrowUp,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(formatDate(item.date), style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            '$sign ${formatRupiah(item.amount)}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
