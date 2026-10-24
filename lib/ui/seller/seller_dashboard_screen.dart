import '../../core/constants/app_surfaces.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/anim.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/listing_status.dart';
import '../../data/repositories/seller_repository.dart';
import '../../domain/shelf_life_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/agrarian_icon.dart';
import '../common/widgets/top_up_sheet.dart';
import '../common/widgets/wallet_header.dart';

/// Layar dasbor seller/penjual LINAKAN.
/// Banner gradien berani, animasi angka KPI, dan transisi kartu mikro.
class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  final ShelfLifeService _shelfLife = ShelfLifeService();

  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _cardFades = List.generate(5, (i) {
      final start = i * 0.12;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: AppMotion.curve),
        ),
      );
    });

    _cardSlides = List.generate(5, (i) {
      final start = i * 0.12;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.16),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: AppMotion.curve),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUserId;
      if (uid != null) {
        context.read<WalletProvider>().loadBalance(uid, 'seller');
      }
      context.read<ListingProvider>().loadAll();
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final listingProv = context.watch<ListingProvider>();
    final txProv = context.watch<TransactionProvider>();
    final uid = auth.currentUserId ?? '';

    final seller = context.read<SellerRepository>().getById(uid);
    final sellerName = seller?.name ?? 'Seller';
    final sellerType = seller?.type ?? '';

    final myListings = listingProv.getMyListings(uid);
    final activeListings = myListings
        .where((l) =>
            l.status == ListingStatus.available &&
            !_shelfLife.isExpired(l.category, l.createdAt))
        .toList();
    final expiringSoon = myListings.where((l) {
      if (l.status != ListingStatus.available) return false;
      final exp = _shelfLife.getExpiryDate(l.category, l.createdAt);
      final rem = exp.difference(DateTime.now());
      return !rem.isNegative && rem.inHours <= 24;
    }).length;
    final reserved =
        myListings.where((l) => l.status == ListingStatus.reserved).length;
    final myTx =
        txProv.getMyTransactions(uid).where((t) => t.sellerId == uid).toList();
    final completed = myTx.where((t) => t.status == 'completed').length;
    final earnings = myTx
        .where((t) => t.status == 'completed')
        .fold<int>(0, (s, t) => s + t.sellerReceives);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: 0,
        onTap: _onNavTap,
        userType: UserType.seller,
      ),
      body: Stack(
        children: [
          // Latar biru solid di belakang header dan lembar konten.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.kColorPrimary),
            ),
          ),
          // Header wallet.
          _DashboardBanner(
            sellerName: sellerName,
            sellerType: sellerType,
            valueLabel: 'Saldo',
            value: walletProvider.formattedBalance,
            onLogout: () {
              context.read<AuthProvider>().logout();
              context.go('/auth/login');
            },
            onTopUp: () => showTopUpSheet(context),
            actions: [
              HeaderAction(
                label: 'Tambah Limbah',
                icon: PhosphorIconsLight.plus,
                symbol: AgrarianSymbol.sprout,
                primary: true,
                onTap: () => context.go('/seller/create-listing'),
              ),
              HeaderAction(
                label: 'Listing',
                icon: PhosphorIconsLight.clipboard,
                symbol: AgrarianSymbol.harvestCrate,
                onTap: () => context.go('/seller/listings'),
              ),
              HeaderAction(
                label: 'Transaksi',
                icon: PhosphorIconsLight.receipt,
                symbol: AgrarianSymbol.receiptScale,
                onTap: () => context.go('/seller/transactions'),
              ),
            ],
          ),
          // Draggable sheet with content.
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              key: const ValueKey('dashboard-content-sheet'),
              decoration: const BoxDecoration(
                color: AppColors.kColorBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.kColorShadow,
                      blurRadius: 12,
                      offset: Offset(0, -4)),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  const SizedBox(height: 8), // drag handle space
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ringkasan Hari Ini',
                          style: AppTextStyles.heading3),
                      IconButton(
                        icon: const Icon(PhosphorIconsLight.arrowsClockwise,
                            size: 20, color: AppColors.kColorPrimary),
                        onPressed: () {
                          context.read<ListingProvider>().loadAll();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data diperbarui'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AnimKpiCard(
                          fade: _cardFades[0],
                          slide: _cardSlides[0],
                          icon: PhosphorIconsLight.package,
                          label: 'Listing Aktif',
                          value: activeListings.length,
                          color: AppColors.kColorPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnimKpiCard(
                          fade: _cardFades[1],
                          slide: _cardSlides[1],
                          icon: PhosphorIconsLight.clock,
                          label: 'Hampir Expired',
                          value: expiringSoon,
                          color: AppColors.kColorAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AnimKpiCard(
                          fade: _cardFades[2],
                          slide: _cardSlides[2],
                          icon: PhosphorIconsLight.shoppingBag,
                          label: 'Dipesan',
                          value: reserved,
                          color: AppColors.kColorPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnimKpiCard(
                          fade: _cardFades[3],
                          slide: _cardSlides[3],
                          icon: PhosphorIconsLight.checkCircle,
                          label: 'Selesai',
                          value: completed,
                          color: AppColors.kColorSuccess,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _cardFades[4],
                    child: Column(
                      children: [
                        SlideTransition(
                          position: _cardSlides[4],
                          child: _EarningsCard(earnings: earnings),
                        ),
                        const SizedBox(height: 24),
                        _EarningsChart(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildRecentListings(context, activeListings),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentListings(
      BuildContext context, List<ListingModel> listings) {
    if (listings.isEmpty) return const SizedBox.shrink();
    final recent = listings.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
                child: Text('Listing Terbaru', style: AppTextStyles.heading3)),
            TextButton(
              onPressed: () => context.go('/seller/listings'),
              child: Text(
                'Lihat semua →',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.kColorPrimary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...recent.map((l) => _RecentListingTile(listing: l)),
      ],
    );
  }

  void _onNavTap(int index) {
    switch (index) {
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

// ---------------------------------------------------------------------------
// Banner Header
// ---------------------------------------------------------------------------

class _DashboardBanner extends StatelessWidget {
  final String sellerName;
  final String sellerType;
  final VoidCallback onLogout;
  final String valueLabel;
  final String value;
  final List<HeaderAction> actions;
  final VoidCallback? onTopUp;

  const _DashboardBanner({
    required this.sellerName,
    required this.sellerType,
    required this.onLogout,
    required this.valueLabel,
    required this.value,
    required this.actions,
    this.onTopUp,
  });

  String get _typeLabel {
    switch (sellerType) {
      case 'irt':
        return 'IRT';
      default:
        return 'UMKM';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WalletHeader(
      valueLabel: valueLabel,
      value: value,
      greetingName: sellerName,
      badge: _typeLabel,
      onLogout: onLogout,
      onTopUp: onTopUp,
      actions: actions,
    );
  }
}

// ---------------------------------------------------------------------------
// Animated KPI Card
// ---------------------------------------------------------------------------

class _AnimKpiCard extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _AnimKpiCard({
    required this.fade,
    required this.slide,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: PressableScale(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kColorSurfaceSoft,
              borderRadius: AppRadius.cardBorder,
              border: Border.all(color: AppColors.kColorBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.kColorShadow,
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 12),
                AnimatedCounter(
                  value: value,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.kColorMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Earnings Card
// ---------------------------------------------------------------------------

class _EarningsCard extends StatelessWidget {
  final int earnings;
  const _EarningsCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.kColorPrimary,
          borderRadius: AppRadius.cardBorder,
          boxShadow: const [
            BoxShadow(
              color: AppColors.kColorShadow,
              blurRadius: 18,
              offset: Offset(0, 6),
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
                    'Total Pendapatan',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.kColorOnPrimary.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCounter(
                    value: earnings,
                    formatter: (v) => formatRupiah(v),
                    style: AppTextStyles.displayMedium.copyWith(
                      fontSize: 22,
                      color: AppColors.kColorOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dari transaksi yang selesai',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.kColorOnPrimary.withAlpha(175),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              PhosphorIconsLight.piggyBank,
              color: AppColors.kColorOnPrimary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Listing Tile
// ---------------------------------------------------------------------------

class _RecentListingTile extends StatelessWidget {
  final ListingModel listing;
  const _RecentListingTile({required this.listing});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppSurfaces.ivory,
          boxShadow: AppSurfaces.raisedShadow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.kColorBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                  ? Image.network(
                      listing.imageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(),
                    )
                  : _iconBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.wasteName,
                    style: AppTextStyles.heading3.copyWith(fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${listing.weight.toStringAsFixed(1)} kg · ${formatRupiah(listing.finalPrice)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.kColorMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.kColorSuccessBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Aktif',
                style: AppTextStyles.badge
                    .copyWith(color: AppColors.kColorSuccess),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
        width: 52,
        height: 52,
        color: AppColors.kColorBorder,
        child: const Icon(PhosphorIconsLight.package,
            color: AppColors.kColorMuted, size: 24),
      );
}

// ---------------------------------------------------------------------------
// Earnings Chart
// ---------------------------------------------------------------------------

class _EarningsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const spots = [
      FlSpot(0, 2.4),
      FlSpot(1, 3.1),
      FlSpot(2, 2.8),
      FlSpot(3, 4.2),
      FlSpot(4, 5.0),
      FlSpot(5, 4.6),
      FlSpot(6, 5.8),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tren Pendapatan',
                        style: AppTextStyles.heading3),
                    const SizedBox(height: 2),
                    Text('7 hari terakhir',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.kColorMuted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.kColorPrimarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsLight.arrowUpRight,
                        size: 12, color: AppColors.kColorPrimary),
                    const SizedBox(width: 4),
                    Text('+18%',
                        style: AppTextStyles.badge
                            .copyWith(color: AppColors.kColorPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 7,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.kColorBorder.withAlpha(120),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[i],
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.kColorMuted)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.32,
                    barWidth: 3,
                    color: AppColors.kColorPrimary,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.kColorPrimary.withAlpha(35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }
}
