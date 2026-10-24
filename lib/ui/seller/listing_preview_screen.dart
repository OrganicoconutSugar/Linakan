import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../common/widgets/countdown_widget.dart';
import '../common/widgets/linakan_badge.dart';
import '../common/widgets/linakan_button.dart';
import '../common/widgets/map_placeholder.dart';
import '../common/widgets/shelf_life_bar.dart';
import '../common/widgets/status_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Pratinjau listing sebelum diterbitkan.
/// Menerima [ListingModel] via GoRouter extra.
class ListingPreviewScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingPreviewScreen({super.key, required this.listing});

  @override
  State<ListingPreviewScreen> createState() => _ListingPreviewScreenState();
}

class _ListingPreviewScreenState extends State<ListingPreviewScreen> {
  bool _isPublishing = false;

  Future<void> _onTerbitkan() async {
    setState(() => _isPublishing = true);
    try {
      await context.read<ListingProvider>().addListing(widget.listing);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing berhasil diterbitkan!'),
          backgroundColor: AppColors.kColorSuccess,
        ),
      );
      context.go('/seller/listings');
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.toString()),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Pratinjau Listing'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pesan pratinjau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.kColorAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.kColorAccent.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsLight.eye,
                    color: AppColors.kColorAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ini adalah pratinjau. Periksa kembali sebelum menerbitkan.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.kColorAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kartu utama listing
          Container(
            decoration: BoxDecoration(
              color: AppSurfaces.ivory,
              boxShadow: AppSurfaces.raisedShadow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kColorBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder gambar
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: AppColors.kColorBorder,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsLight.image,
                          size: 48,
                          color: AppColors.kColorMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Foto belum tersedia',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.kColorMuted),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge kategori + status
                      Row(
                        children: [
                          LinakanBadge(label: listing.category.name),
                          const SizedBox(width: 8),
                          StatusBadge(status: listing.status),
                          const SizedBox(width: 8),
                          if (listing.sellerType.isNotEmpty)
                            LinakanBadge(
                              label: listing.sellerType.toUpperCase(),
                              color: AppColors.kColorBorder,
                              textColor: AppColors.kColorMuted,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nama limbah
                      Text(listing.wasteName, style: AppTextStyles.heading2),
                      const SizedBox(height: 8),

                      // Penjual
                      Row(
                        children: [
                          const Icon(PhosphorIconsLight.storefront,
                              size: 16, color: AppColors.kColorMuted),
                          const SizedBox(width: 4),
                          Text(
                            listing.sellerName,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.kColorMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Berat & harga
                      Row(
                        children: [
                          _InfoChip(
                            icon: PhosphorIconsLight.scales,
                            label: '${listing.weight.toStringAsFixed(1)} kg',
                          ),
                          const SizedBox(width: 12),
                          _InfoChip(
                            icon: PhosphorIconsLight.currencyDollar,
                            label: '${formatRupiah(listing.pricePerKg)}/kg',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Total harga
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total harga:', style: AppTextStyles.body),
                          Text(
                            formatRupiah(listing.totalPrice),
                            style: AppTextStyles.price,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lokasi
                      const Text(
                        'Alamat Pengambilan',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 8),
                      MapPlaceholder(
                        address: listing.pickupAddress,
                        height: 130,
                      ),
                      const SizedBox(height: 16),

                      // Shelf Life Bar
                      const Text(
                        'Masa Simpan',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 8),
                      ShelfLifeBar(
                        category: listing.category,
                        createdAt: listing.createdAt,
                      ),
                      const SizedBox(height: 8),
                      CountdownWidget(
                        category: listing.category,
                        createdAt: listing.createdAt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Tombol Edit & Terbitkan
          Row(
            children: [
              Expanded(
                child: LinakanButton(
                  label: 'Edit',
                  onPressed: () => context.pop(),
                  variant: LinakanButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinakanButton(
                  label: 'Terbitkan',
                  onPressed: _isPublishing ? null : _onTerbitkan,
                  isLoading: _isPublishing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.kColorMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.kColorText),
        ),
      ],
    );
  }
}
