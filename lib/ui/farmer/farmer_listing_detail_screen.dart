import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/listing_status.dart';
import '../../data/models/match_result_model.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../data/repositories/seller_repository.dart';
import '../../domain/matching_service.dart';
import '../../domain/shelf_life_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/matching_provider.dart';
import '../common/widgets/countdown_widget.dart';
import '../common/widgets/linakan_badge.dart';
import '../common/widgets/map_placeholder.dart';
import '../common/widgets/shelf_life_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

/// Layar detail listing peternak — info limbah, lokasi, masa simpan,
/// kompatibilitas, dan aksi konfirmasi & beli.
class FarmerListingDetailScreen extends StatefulWidget {
  final String listingId;

  const FarmerListingDetailScreen({super.key, required this.listingId});

  @override
  State<FarmerListingDetailScreen> createState() =>
      _FarmerListingDetailScreenState();
}

class _FarmerListingDetailScreenState extends State<FarmerListingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final listingProvider = context.read<ListingProvider>();
    final matchingProvider = context.read<MatchingProvider>();
    final authProvider = context.read<AuthProvider>();
    final farmerRepository = context.read<FarmerRepository>();
    await listingProvider.loadAll();
    if (matchingProvider.allMatches.isEmpty) {
      final userId = authProvider.currentUserId;
      if (userId == null) return;
      final farmer = farmerRepository.getById(userId);
      if (farmer != null) {
        await matchingProvider.computeMatches(farmer);
      }
    }
  }

  MatchResultModel? _resolveMatch(
    MatchingProvider matchingProvider,
    ListingModel listing,
  ) {
    final cached = matchingProvider.allMatches
        .where((m) => m.listing.id == listing.id)
        .firstOrNull;
    if (cached != null) return cached;

    // Fallback: hitung segar untuk listing yang tidak ada di cache
    // (mis. sudah dipesan sehingga terfilter dari activeListings).
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return null;
    final farmer = context.read<FarmerRepository>().getById(userId);
    if (farmer == null) return null;
    return MatchingService(ShelfLifeService())
        .calculateCompatibility(listing, farmer);
  }

  void _showContactSeller(ListingModel listing) {
    final seller = context.read<SellerRepository>().getById(listing.sellerId);
    final sellerName = seller?.name ?? listing.sellerName;
    final sellerPhone = seller?.phone ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hubungi Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sellerName, style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text('Telepon: $sellerPhone',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.kColorMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur WhatsApp aktif saat backend tersedia'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorWhatsApp,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Hubungi via WhatsApp (Demo)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = context.watch<ListingProvider>();
    final matchingProvider = context.watch<MatchingProvider>();

    final listing = listingProvider.listings
        .where((l) => l.id == widget.listingId)
        .firstOrNull;

    if (listing == null) {
      return Scaffold(
        backgroundColor: AppColors.kColorBackground,
        appBar: AppBar(
          title: const Text('Detail Listing'),
          backgroundColor: AppColors.kColorSurface,
          foregroundColor: AppColors.kColorText,
        ),
        body: const Center(
          child: Text('Listing tidak ditemukan.'),
        ),
      );
    }

    final match = _resolveMatch(matchingProvider, listing);
    final isAvailable = listing.status == ListingStatus.available;

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Detail Listing'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
      ),
      bottomNavigationBar: _buildBottomBar(listing, isAvailable),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero image
          _buildHeroImage(listing),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + badge kategori
                Row(
                  children: [
                    LinakanBadge(label: listing.category.name),
                    const SizedBox(width: 6),
                    if (match?.isInstantMatch == true)
                      const LinakanBadge(
                        label: 'Instant Match',
                        color: AppColors.kColorWarning,
                        textColor: AppColors.kColorText,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(listing.wasteName, style: AppTextStyles.heading1),
                const SizedBox(height: 12),

                // Berat & harga
                _InfoRow(
                  icon: PhosphorIconsLight.scales,
                  label: 'Berat',
                  value: '${listing.weight.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: PhosphorIconsLight.creditCard,
                  label: 'Harga',
                  value:
                      '${formatRupiah(listing.pricePerKg)}/kg · Total: ${formatRupiah(listing.finalPrice)}',
                ),

                const SizedBox(height: 24),
                // Lokasi pengambilan
                const Text('Lokasi Pengambilan', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                MapPlaceholder(address: listing.pickupAddress),

                const SizedBox(height: 24),
                // Masa simpan
                const Text('Masa Simpan', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                CountdownWidget(
                  category: listing.category,
                  createdAt: listing.createdAt,
                ),
                const SizedBox(height: 8),
                ShelfLifeBar(
                  category: listing.category,
                  createdAt: listing.createdAt,
                ),

                const SizedBox(height: 24),
                // Kompatibilitas
                const Text('Kompatibilitas', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                if (match == null)
                  Text(
                    'Belum ada data kecocokan. Buka kembali dari Dasbor.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.kColorMuted),
                  )
                else ...[
                  _ScoreCircle(score: match.score),
                  const SizedBox(height: 16),
                  _BreakdownRow(
                    label: 'Kategori',
                    weight: '${(AppConstants.kWeightCategory * 100).toInt()}%',
                    score: match.categoryScore,
                  ),
                  const SizedBox(height: 12),
                  _BreakdownRow(
                    label: 'Lokasi',
                    weight: '${(AppConstants.kWeightLocation * 100).toInt()}%',
                    score: match.locationScore,
                  ),
                  const SizedBox(height: 12),
                  _BreakdownRow(
                    label: 'Kapasitas',
                    weight: '${(AppConstants.kWeightCapacity * 100).toInt()}%',
                    score: match.capacityScore,
                  ),
                  const SizedBox(height: 16),
                  if (match.categoryReasons.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.kColorPrimary.withAlpha(16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.categoryReasons.join('\n'),
                        style: AppTextStyles.body,
                      ),
                    ),
                ],

                const SizedBox(height: 24),
                // Hubungi seller
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showContactSeller(listing),
                    icon: const Icon(PhosphorIconsLight.phone),
                    label: const Text('Hubungi Seller'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kColorPrimary,
                      side: const BorderSide(color: AppColors.kColorPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(ListingModel listing) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: listing.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 220,
                color: AppColors.kColorBorder,
                child: const Center(
                  child: Icon(PhosphorIconsLight.image,
                      color: AppColors.kColorMuted),
                ),
              ),
              errorWidget: (_, __, ___) => _imageFallback(),
            )
          : _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 220,
      color: AppColors.kColorBorder,
      child: const Center(
        child: Icon(PhosphorIconsLight.imageBroken,
            color: AppColors.kColorMuted, size: 48),
      ),
    );
  }

  Widget _buildBottomBar(ListingModel listing, bool isAvailable) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.kColorSurface,
          border: Border(top: BorderSide(color: AppColors.kColorBorder)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAvailable
                ? () => context.go('/farmer/checkout/${listing.id}')
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorPrimary,
              foregroundColor: AppColors.kColorOnPrimary,
              disabledBackgroundColor: AppColors.kColorMuted.withAlpha(80),
              disabledForegroundColor: AppColors.kColorOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.buttonBorder,
              ),
            ),
            child: Text(
              isAvailable ? 'Konfirmasi & Beli' : 'Sudah Dipesan',
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.kColorMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.body),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int score;

  const _ScoreCircle({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= AppConstants.kInstantMatchThreshold
        ? AppColors.kColorSuccess
        : score >= 60
            ? AppColors.kColorWarning
            : AppColors.kColorDanger;
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(24),
          border: Border.all(color: color, width: 3),
        ),
        child: Center(
          child: Text(
            '$score%',
            style: AppTextStyles.heading1.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String weight;
  final int score;

  const _BreakdownRow({
    required this.label,
    required this.weight,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label (bobot $weight)', style: AppTextStyles.body),
            Text('$score%',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.kColorBorder,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.kColorPrimary),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
