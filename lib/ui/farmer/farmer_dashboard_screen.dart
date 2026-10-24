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
import '../../data/repositories/farmer_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/matching_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/agrarian_icon.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/match_card.dart';
import '../common/widgets/top_up_sheet.dart';
import '../common/widgets/wallet_header.dart';

/// Layar dasbor peternak LINAKAN.
class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId;
    if (userId == null) return;

    final farmer = context.read<FarmerRepository>().getById(userId);
    final listingProvider = context.read<ListingProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final matchingProvider = context.read<MatchingProvider>();
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.loadBalance(userId, 'farmer');
    await listingProvider.loadAll();
    await transactionProvider.loadTransactions();
    if (farmer != null) {
      await matchingProvider.computeMatches(farmer);
    }
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;
    final farmer = context.read<FarmerRepository>().getById(userId);
    if (farmer == null) return;
    final listingProvider = context.read<ListingProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final matchingProvider = context.read<MatchingProvider>();
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.loadBalance(userId, 'farmer');
    await listingProvider.loadAll();
    await transactionProvider.loadTransactions();
    await matchingProvider.computeMatches(farmer);
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        context.go('/farmer/dashboard');
        break;
      case 1:
        context.go('/farmer/matches');
        break;
      case 2:
        context.go('/farmer/marketplace');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        context.go('/farmer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final matchingProvider = context.watch<MatchingProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final userId = authProvider.currentUserId ?? '';

    final farmerName =
        context.watch<FarmerRepository>().getById(userId)?.name ?? 'Peternak';

    final instantMatches = matchingProvider.instantMatches;
    final allMatches = matchingProvider.allMatches;
    final myTransactions = transactionProvider.getMyTransactions(userId)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final reservedCount =
        myTransactions.where((t) => t.status == 'confirmed').length;
    final completedCount =
        myTransactions.where((t) => t.status == 'completed').length;

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      extendBody: true,
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        userType: UserType.farmer,
      ),
      body: Stack(
        children: [
          // Latar biru solid di belakang header dan lembar konten.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.kColorPrimary),
            ),
          ),
          // Header wallet (shared widget).
          WalletHeader(
            valueLabel: 'Saldo',
            value: context.watch<WalletProvider>().formattedBalance,
            greetingName: farmerName,
            badge: 'Instant Match aktif',
            onLogout: () {
              context.read<AuthProvider>().logout();
              context.go('/auth/login');
            },
            onTopUp: () => showTopUpSheet(context),
            actions: [
              HeaderAction(
                label: 'Instant Match',
                icon: PhosphorIconsLight.lightning,
                symbol: AgrarianSymbol.exchange,
                primary: true,
                onTap: () => context.go('/farmer/matches'),
              ),
              HeaderAction(
                label: 'Pasar',
                icon: PhosphorIconsLight.storefront,
                symbol: AgrarianSymbol.market,
                onTap: () => context.go('/farmer/marketplace'),
              ),
              HeaderAction(
                label: 'Dompet',
                icon: PhosphorIconsLight.wallet,
                symbol: AgrarianSymbol.coinPouch,
                onTap: () => context.go('/wallet'),
              ),
            ],
          ),
// Draggable sheet.
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
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.kColorBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(PhosphorIconsLight.arrowClockwise,
                            size: 20),
                        tooltip: 'Muat ulang',
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Instant Match untuk Anda
                  FadeSlideIn(
                    delay: Anim.stagger(1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Instant Match untuk Anda',
                            style: AppTextStyles.heading3),
                        if (instantMatches.isNotEmpty)
                          TextButton(
                            onPressed: () => context.go('/farmer/matches'),
                            child: const Text('Lihat Semua →'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (instantMatches.isEmpty)
                    const EmptyState(
                      icon: PhosphorIconsLight.lightning,
                      title: 'Belum ada Instant Match.',
                      subtitle:
                          'Perbarui profil Anda atau tunggu listing baru.',
                    )
                  else
                    SizedBox(
                      height: 430,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: instantMatches.length > 3
                            ? 3
                            : instantMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final match = instantMatches[index];
                          return FadeSlideIn(
                            delay: Anim.stagger(index, base: 120),
                            begin: const Offset(0.1, 0),
                            child: SizedBox(
                              width: 280,
                              child: MatchCard(
                                matchResult: match,
                                onDetailPressed: () => context
                                    .go('/farmer/listing/${match.listing.id}'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),

                  // KPI row
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 320),
                    child: Text('Ringkasan', style: AppTextStyles.heading3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FadeSlideIn(
                          delay: Anim.stagger(0, base: 360),
                          child: _KpiCard(
                            label: 'Total Cocok',
                            value: allMatches.length,
                            icon: PhosphorIconsLight.magnifyingGlass,
                            color: AppColors.kColorPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeSlideIn(
                          delay: Anim.stagger(1, base: 360),
                          child: _KpiCard(
                            label: 'Dipesan',
                            value: reservedCount,
                            icon: PhosphorIconsLight.shoppingBag,
                            color: AppColors.kColorPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeSlideIn(
                          delay: Anim.stagger(2, base: 360),
                          child: _KpiCard(
                            label: 'Selesai',
                            value: completedCount,
                            icon: PhosphorIconsLight.checkCircle,
                            color: AppColors.kColorSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chart
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 320),
                    child: Text('Aktivitas Transaksi',
                        style: AppTextStyles.heading3),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: _TransactionChart(),
                  ),
                  const SizedBox(height: 28),

                  // Jelajahi Pasar
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 480),
                    child:
                        Text('Jelajahi Pasar', style: AppTextStyles.heading3),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 540),
                    child: PressableScale(
                      onTap: () => context.go('/farmer/marketplace'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.kColorPrimary,
                          borderRadius: AppRadius.cardBorder,
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.kColorShadow,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsLight.storefront,
                                color: AppColors.kColorOnPrimary, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pasar Limbah LINAKAN',
                                    style: AppTextStyles.heading3,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Jelajahi semua listing limbah pangan tersedia.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.kColorOnPrimary
                                          .withAlpha(205),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(PhosphorIconsLight.arrowRight,
                                color: AppColors.kColorOnPrimary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu KPI dengan angka animasi hitung naik.
class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.kColorSurfaceSoft,
          boxShadow: AppSurfaces.raisedShadow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.kColorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            AnimatedCounter(
              value: value,
              style: AppTextStyles.heading2.copyWith(color: color),
            ),
            const SizedBox(height: 2),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction Chart
// ---------------------------------------------------------------------------

class _TransactionChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = [2.0, 3.5, 2.8, 4.5, 3.6, 5.2, 4.8];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: 6,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
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
          barTouchData: BarTouchData(enabled: false),
          barGroups: List.generate(bars.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i],
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                  color:
                      i.isEven ? AppColors.kColorPrimary : AppColors.kColorLime,
                ),
              ],
            );
          }),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }
}
