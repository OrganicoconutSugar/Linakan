import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/listing_status.dart';
import '../../data/models/waste_category.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../domain/shelf_life_service.dart';
import '../../providers/listing_provider.dart';
import '../../providers/transaction_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Layar dasbor admin LINAKAN.
/// KPI dihitung dari data provider langsung (bukan hard-code).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ShelfLifeService _shelfLifeService = ShelfLifeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listingProvider = context.read<ListingProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      listingProvider.loadAll();
      transactionProvider.loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final farmerRepo = context.watch<FarmerRepository>();

    final isLoading =
        listingProvider.isLoading || transactionProvider.isLoading;
    final error = listingProvider.error ?? transactionProvider.error;

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Admin Dashboard LINAKAN'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorBanner(
                  message: error,
                  onRetry: () {
                    context.read<ListingProvider>().loadAll();
                    context.read<TransactionProvider>().loadTransactions();
                  },
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Ringkasan Operasional',
                        style: AppTextStyles.heading2),
                    const SizedBox(height: 16),
                    _buildKpiGrid(listingProvider),
                    const SizedBox(height: 28),
                    _buildSupplySection(listingProvider),
                    const SizedBox(height: 24),
                    _buildDemandSection(farmerRepo),
                    const SizedBox(height: 24),
                    _buildRevenueSection(transactionProvider),
                    const SizedBox(height: 28),
                    _buildNavLinks(),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // KPI grid
  // ---------------------------------------------------------------------------
  Widget _buildKpiGrid(ListingProvider listingProvider) {
    final listings = listingProvider.listings;
    final activeCount =
        listings.where((l) => l.status == ListingStatus.available).length;
    final totalWeight = listings.fold<double>(0, (s, l) => s + l.weight);
    final matchableCount = listings
        .where((l) =>
            l.status == ListingStatus.available &&
            !_shelfLifeService.isExpired(l.category, l.createdAt))
        .length;
    final reservedCount =
        listings.where((l) => l.status == ListingStatus.reserved).length;
    final completedCount =
        listings.where((l) => l.status == ListingStatus.completed).length;
    final expiringSoon = listings.where((l) {
      if (l.status != ListingStatus.available) return false;
      final expiry = _shelfLifeService.getExpiryDate(l.category, l.createdAt);
      final remaining = expiry.difference(DateTime.now());
      return !remaining.isNegative && remaining.inHours <= 24;
    }).length;

    final kpis = [
      _Kpi('Listing Aktif', '$activeCount', PhosphorIconsLight.package,
          AppColors.kColorSuccess),
      _Kpi('Total Limbah', '${totalWeight.toStringAsFixed(1)} kg',
          PhosphorIconsLight.scales, AppColors.kColorPrimary),
      _Kpi('Cocok Aktif', '$matchableCount', PhosphorIconsLight.lightning,
          AppColors.kColorAccent),
      _Kpi('Dipesan', '$reservedCount', PhosphorIconsLight.shoppingBag,
          AppColors.kColorWarning),
      _Kpi('Selesai', '$completedCount', PhosphorIconsLight.checkCircle,
          AppColors.kColorPrimaryLight),
      _Kpi('Segera Kadaluarsa', '$expiringSoon', PhosphorIconsLight.clock,
          AppColors.kColorDanger),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpis.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) => _KpiCard(kpi: kpis[index]),
    );
  }

  // ---------------------------------------------------------------------------
  // Supply by category (bar simulation)
  // ---------------------------------------------------------------------------
  Widget _buildSupplySection(ListingProvider listingProvider) {
    final byCategory = <WasteCategory, double>{};
    for (final l in listingProvider.listings) {
      byCategory[l.category] = (byCategory[l.category] ?? 0) + l.weight;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxWeight = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Pasokan per Kategori',
      child: entries.isEmpty
          ? const Text('Belum ada data pasokan.',
              style: AppTextStyles.bodySmall)
          : Column(
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BarRow(
                      label: e.key.name,
                      valueText: '${e.value.toStringAsFixed(1)} kg',
                      fraction:
                          (e.value / maxWeight).clamp(0.0, 1.0).toDouble(),
                    ),
                  ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Demand by livestock (bar simulation)
  // ---------------------------------------------------------------------------
  Widget _buildDemandSection(FarmerRepository farmerRepo) {
    final farmers = farmerRepo.getAll();
    final byLivestock = <String, int>{};
    for (final f in farmers) {
      for (final lt in f.livestock) {
        byLivestock[lt] = (byLivestock[lt] ?? 0) + 1;
      }
    }
    final labels = <String, String>{
      'bebek': 'Bebek',
      'ayam': 'Ayam',
      'unggas_lainnya': 'Unggas Lainnya',
      'sapi': 'Sapi',
      'kambing': 'Kambing',
      'kelinci': 'Kelinci',
    };
    final entries = byLivestock.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Permintaan per Jenis Ternak',
      child: entries.isEmpty
          ? const Text('Belum ada data peternak.',
              style: AppTextStyles.bodySmall)
          : Column(
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BarRow(
                      label: labels[e.key] ?? e.key,
                      valueText: '${e.value} peternak',
                      fraction: (e.value / maxCount).clamp(0.0, 1.0).toDouble(),
                    ),
                  ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Revenue
  // ---------------------------------------------------------------------------
  Widget _buildRevenueSection(TransactionProvider transactionProvider) {
    final revenue = transactionProvider.transactions
        .where((t) => t.status == 'completed')
        .fold<int>(0, (s, t) => s + t.platformFee);
    return _SectionCard(
      title: 'Pendapatan Platform',
      child: Row(
        children: [
          const Icon(PhosphorIconsLight.creditCard,
              color: AppColors.kColorPrimary),
          const SizedBox(width: 8),
          const Text('Total biaya layanan dari transaksi selesai:',
              style: AppTextStyles.body),
          const Spacer(),
          Text(formatRupiah(revenue),
              style: AppTextStyles.price.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Nav links
  // ---------------------------------------------------------------------------
  Widget _buildNavLinks() {
    return Column(
      children: [
        _NavCard(
          icon: PhosphorIconsLight.clipboard,
          title: 'Kelola Listing',
          subtitle: 'Lihat dan ekspor semua listing limbah.',
          onTap: () => context.go('/admin/listings'),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: PhosphorIconsLight.receipt,
          title: 'Transaksi',
          subtitle: 'Lihat dan ekspor semua transaksi.',
          onTap: () => context.go('/admin/transactions'),
        ),
      ],
    );
  }
}

/// Kartu KPI admin.
class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Kpi(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kColorSurfaceSoft,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(kpi.icon, color: kpi.color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(kpi.value,
              style: AppTextStyles.heading2.copyWith(color: kpi.color)),
          const SizedBox(height: 2),
          Text(kpi.label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.kColorMuted)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double fraction;
  const _BarRow({
    required this.label,
    required this.valueText,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 12,
              backgroundColor: AppColors.kColorBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.kColorPrimary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(valueText,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buka $title',
      child: Material(
        color: AppColors.kColorSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kColorBorder),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.kColorPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.heading3),
                      Text(subtitle,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.kColorMuted)),
                    ],
                  ),
                ),
                const Icon(PhosphorIconsLight.caretRight,
                    color: AppColors.kColorMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsLight.warningCircle,
                color: AppColors.kColorDanger, size: 48),
            const SizedBox(height: 12),
            Text(message,
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
}
