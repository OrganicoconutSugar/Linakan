import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/empty_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SellerTransactionsScreen extends StatefulWidget {
  const SellerTransactionsScreen({super.key});
  @override
  State<SellerTransactionsScreen> createState() =>
      _SellerTransactionsScreenState();
}

class _SellerTransactionsScreenState extends State<SellerTransactionsScreen> {
  String _filter = 'semua'; // semua | confirmed | completed | cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  List<TransactionModel> _filtered(List<TransactionModel> all, String uid) {
    final mine = all.where((t) => t.sellerId == uid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_filter == 'semua') return mine;
    return mine.where((t) => t.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUserId ?? '';
    final txProv = context.watch<TransactionProvider>();
    final farmerRepo = context.read<FarmerRepository>();
    final all = txProv.transactions;
    final shown = _filtered(all, uid);

    // Ringkasan
    final mine = all.where((t) => t.sellerId == uid).toList();
    final totalEarnings = mine
        .where((t) => t.status == 'completed')
        .fold<int>(0, (s, t) => s + t.sellerReceives);
    final pendingCount = mine.where((t) => t.status == 'confirmed').length;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.kColorSurface,
            foregroundColor: AppColors.kColorText,
            elevation: 0,
            title: Text('Transaksi',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.kColorText)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: _TxFilterChips(
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Summary banner
            if (mine.isNotEmpty)
              _TxSummaryBanner(
                earnings: totalEarnings,
                pending: pendingCount,
              ),

            // List
            Expanded(
              child: shown.isEmpty
                  ? const EmptyState(
                      icon: PhosphorIconsLight.receipt,
                      title: 'Belum ada transaksi.',
                      subtitle: 'Transaksi Anda akan muncul di sini.',
                    )
                  : RefreshIndicator(
                      color: AppColors.kColorPrimary,
                      onRefresh: () => txProv.loadTransactions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _TxCard(
                          tx: shown[i],
                          farmerRepo: farmerRepo,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: 2,
        onTap: _onNavTap,
        userType: UserType.seller,
      ),
    );
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        context.go('/seller/dashboard');
        break;
      case 1:
        context.go('/seller/listings');
        break;
      case 2:
        context.go('/seller/transactions');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        context.go('/seller/profile');
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _TxFilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TxFilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('semua', 'Semua'),
      ('confirmed', 'Dikonfirmasi'),
      ('completed', 'Selesai'),
      ('cancelled', 'Dibatalkan'),
    ];

    return Container(
      height: 44,
      color: AppColors.kColorSurface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return GestureDetector(
            onTap: () => onChanged(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.kColorPrimary
                    : AppColors.kColorBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.kColorPrimary
                      : AppColors.kColorBorder,
                ),
              ),
              child: Text(
                f.$2,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.kColorOnPrimary
                      : AppColors.kColorTextSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary banner
// ─────────────────────────────────────────────────────────────────────────────

class _TxSummaryBanner extends StatelessWidget {
  final int earnings;
  final int pending;

  const _TxSummaryBanner({required this.earnings, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kColorPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.kColorShadow,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Diterima',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.kColorOnPrimary.withAlpha(195),
                  ),
                ),
                Text(
                  formatRupiah(earnings),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kColorOnPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.kColorOnPrimary.withAlpha(48),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Column(
            children: [
              Text(
                '$pending',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kColorOnPrimary,
                ),
              ),
              Text(
                'Menunggu',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.kColorOnPrimary.withAlpha(195),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction card (expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _TxCard extends StatefulWidget {
  final TransactionModel tx;
  final FarmerRepository farmerRepo;

  const _TxCard({required this.tx, required this.farmerRepo});

  @override
  State<_TxCard> createState() => _TxCardState();
}

class _TxCardState extends State<_TxCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  Color get _statusColor {
    switch (widget.tx.status) {
      case 'completed':
        return AppColors.kColorSuccess;
      case 'confirmed':
        return AppColors.kColorAccent;
      case 'cancelled':
        return AppColors.kColorDanger;
      default:
        return AppColors.kColorWarning;
    }
  }

  String get _statusLabel {
    switch (widget.tx.status) {
      case 'completed':
        return 'Selesai';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final farmer = widget.farmerRepo.getById(tx.farmerId);
    final farmerName = farmer?.name ?? tx.farmerId;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppSurfaces.ivory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _expanded ? _statusColor.withAlpha(80) : AppColors.kColorBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.kColorShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header baris
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Status indicator dot
                  Icon(
                    PhosphorIconsLight.receipt,
                    color: _statusColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.wasteName,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          'Pembeli: $farmerName',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.kColorMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          PhosphorIconsLight.caretDown,
                          color: AppColors.kColorMuted,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Detail expandable
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  Divider(height: 1, color: _statusColor.withAlpha(40)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Tanggal',
                          value: formatDateTime(tx.createdAt),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Berat',
                          value: '${tx.listingWeight.toStringAsFixed(1)} kg',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Subtotal',
                          value: formatRupiah(tx.totalPrice),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Biaya LINAKAN (5%)',
                          value: '− ${formatRupiah(tx.platformFee)}',
                          valueColor: AppColors.kColorDanger,
                        ),
                        const Divider(height: 16),
                        _DetailRow(
                          label: 'Anda Menerima',
                          value: formatRupiah(tx.sellerReceives),
                          labelStyle: AppTextStyles.bodyMedium,
                          valueStyle: AppTextStyles.price
                              .copyWith(color: AppColors.kColorSuccess),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final TextStyle? labelStyle, valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: labelStyle ??
                AppTextStyles.body.copyWith(color: AppColors.kColorMuted)),
        Text(
          value,
          style: valueStyle ??
              AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.kColorText,
              ),
        ),
      ],
    );
  }
}
