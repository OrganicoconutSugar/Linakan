import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/listing_status.dart';
import '../../domain/shelf_life_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/status_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

class SellerListingsScreen extends StatefulWidget {
  const SellerListingsScreen({super.key});
  @override
  State<SellerListingsScreen> createState() => _SellerListingsScreenState();
}

class _SellerListingsScreenState extends State<SellerListingsScreen>
    with SingleTickerProviderStateMixin {
  final ShelfLifeService _shelfLife = ShelfLifeService();
  ListingStatus? _filterStatus; // null = semua
  late final AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  List<ListingModel> _filtered(List<ListingModel> all) {
    if (_filterStatus == null) return all;
    return all.where((l) => l.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUserId ?? '';
    final lp = context.watch<ListingProvider>();
    final all = lp.getMyListings(uid);
    final shown = _filtered(all);

    final statusCounts = {
      null: all.length,
      ListingStatus.available:
          all.where((l) => l.status == ListingStatus.available).length,
      ListingStatus.reserved:
          all.where((l) => l.status == ListingStatus.reserved).length,
      ListingStatus.completed:
          all.where((l) => l.status == ListingStatus.completed).length,
      ListingStatus.expired:
          all.where((l) => l.status == ListingStatus.expired).length,
    };

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
            title: Text('Listing Saya',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.kColorText)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${all.length} item',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.kColorMuted),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: _FilterChips(
                selected: _filterStatus,
                counts: statusCounts,
                onChanged: (s) => setState(() => _filterStatus = s),
              ),
            ),
          ),
        ],
        body: shown.isEmpty
            ? const EmptyState(
                icon: PhosphorIconsLight.package,
                title: 'Belum ada listing.',
                subtitle: 'Tambah limbah sekarang dengan tombol +',
              )
            : RefreshIndicator(
                color: AppColors.kColorPrimary,
                onRefresh: () => lp.loadAll(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: shown.length,
                  itemBuilder: (ctx, i) {
                    final listing = shown[i];
                    return _ListingCard(
                      key: ValueKey(listing.id),
                      listing: listing,
                      shelfLife: _shelfLife,
                      onDelete: () => _confirmDelete(ctx, listing.id),
                    );
                  },
                ),
              ),
      ),
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: 1,
        onTap: _onNavTap,
        userType: UserType.seller,
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: FloatingActionButton(
          onPressed: () => context.go('/seller/create-listing'),
          backgroundColor: AppColors.kColorPrimary,
          foregroundColor: AppColors.kColorOnPrimary,
          child: const Icon(PhosphorIconsLight.plus, size: 28),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, String id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Listing?', style: AppTextStyles.heading3),
        content: Text(
          'Listing ini akan dihapus permanen.',
          style: AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorDanger,
              foregroundColor: AppColors.kColorOnPrimary,
              shape:
                  RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await ctx.read<ListingProvider>().deleteListing(id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Text('Listing dihapus.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.kColorSuccess,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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

class _FilterChips extends StatelessWidget {
  final ListingStatus? selected;
  final Map<ListingStatus?, int> counts;
  final ValueChanged<ListingStatus?> onChanged;

  const _FilterChips({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <(ListingStatus?, String)>[
      (null, 'Semua'),
      (ListingStatus.available, 'Tersedia'),
      (ListingStatus.reserved, 'Dipesan'),
      (ListingStatus.completed, 'Selesai'),
      (ListingStatus.expired, 'Expired'),
    ];

    return Container(
      height: 44,
      color: AppColors.kColorSurface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = selected == f.$1;
          final count = counts[f.$1] ?? 0;
          return GestureDetector(
            onTap: () => onChanged(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
                '${f.$2} ($count)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.kColorOnPrimary
                      : AppColors.kColorTextSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Listing card
// ─────────────────────────────────────────────────────────────────────────────

class _ListingCard extends StatefulWidget {
  final ListingModel listing;
  final ShelfLifeService shelfLife;
  final VoidCallback onDelete;

  const _ListingCard({
    super.key,
    required this.listing,
    required this.shelfLife,
    required this.onDelete,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final expiry = widget.shelfLife.getExpiryDate(l.category, l.createdAt);
    final remaining = expiry.difference(DateTime.now());
    final isExpiring = !remaining.isNegative && remaining.inHours <= 24;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppSurfaces.ivory,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpiring
                  ? AppColors.kColorWarning.withAlpha(80)
                  : AppColors.kColorBorder,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.kColorShadow,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Image banner jika ada
              if (l.imageUrl != null && l.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      l.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imageFallback(l.category.name),
                    ),
                  ),
                )
              else
                _imageFallback(l.category.name),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.wasteName,
                              style: AppTextStyles.heading3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            '${l.weight.toStringAsFixed(1)} kg · ${formatRupiah(l.pricePerKg)}/kg',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.kColorMuted),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              StatusBadge(status: l.status),
                              if (isExpiring) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.kColorWarningBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(PhosphorIconsLight.clock,
                                          size: 11,
                                          color: AppColors.kColorWarning),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${remaining.inHours}j tersisa',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.kColorWarning),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(PhosphorIconsLight.trash, size: 20),
                      color: AppColors.kColorDanger.withAlpha(180),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(String category) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.kColorBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Icon(
          PhosphorIconsLight.package,
          size: 36,
          color: AppColors.kColorPrimary,
        ),
      ),
    );
  }
}
