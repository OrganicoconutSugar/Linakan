import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/listing_status.dart';
import '../../domain/shelf_life_service.dart';
import '../../providers/listing_provider.dart';
import '../common/widgets/loading_error_state.dart';
import '../common/widgets/status_badge.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Filter status listing untuk admin.
enum _ListingFilter { semua, tersedia, dipesan, selesai, kadaluarsa }

/// Layar kelola listing admin — semua listing dengan filter status dan
/// ekspor CSV.
class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  final ShelfLifeService _shelfLifeService = ShelfLifeService();
  _ListingFilter _filter = _ListingFilter.semua;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().loadAll();
    });
  }

  bool _matchesFilter(ListingModel l) {
    switch (_filter) {
      case _ListingFilter.semua:
        return true;
      case _ListingFilter.tersedia:
        return l.status == ListingStatus.available;
      case _ListingFilter.dipesan:
        return l.status == ListingStatus.reserved;
      case _ListingFilter.selesai:
        return l.status == ListingStatus.completed;
      case _ListingFilter.kadaluarsa:
        // Termasuk listing yang sudah kadaluarsa menurut ShelfLifeService.
        return _shelfLifeService.isExpired(l.category, l.createdAt);
    }
  }

  List<ListingModel> _filteredList(ListingProvider provider) {
    return provider.listings.where(_matchesFilter).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _exportCsv(List<ListingModel> listings) async {
    setState(() => _exporting = true);
    try {
      final rows = listings
          .map((l) => [
                l.id,
                l.sellerName,
                l.category.name,
                l.weight.toStringAsFixed(1),
                l.status.label,
                l.createdAt.toIso8601String(),
              ])
          .toList();
      await exportCsvToTempFile(
        fileName: 'linakan_listings.csv',
        header: const [
          'id',
          'seller',
          'category',
          'weight',
          'status',
          'createdAt'
        ],
        rows: rows,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CSV berhasil diekspor: linakan_listings.csv\n'
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
    final listingProvider = context.watch<ListingProvider>();

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsLight.arrowLeft),
          tooltip: 'Kembali ke Dasbor Admin',
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('Kelola Listing'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exporting
            ? null
            : () => _exportCsv(_filteredList(listingProvider)),
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
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.kColorBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Semua', _ListingFilter.semua),
                  _filterChip('Tersedia', _ListingFilter.tersedia),
                  _filterChip('Dipesan', _ListingFilter.dipesan),
                  _filterChip('Selesai', _ListingFilter.selesai),
                  _filterChip('Kadaluarsa', _ListingFilter.kadaluarsa),
                ],
              ),
            ),
          ),
          Expanded(
            child: LoadingErrorState(
              isLoading: listingProvider.isLoading,
              error: listingProvider.error,
              onRetry: () => context.read<ListingProvider>().loadAll(),
              contentBuilder: (context) {
                final filtered = _filteredList(listingProvider);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada listing untuk filter ini.',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _ListingRow(listing: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _ListingFilter filter) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        selectedColor: AppColors.kColorPrimary,
        labelStyle: TextStyle(
          color: selected ? AppColors.kColorOnPrimary : AppColors.kColorText,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.kColorSurface,
        side: const BorderSide(color: AppColors.kColorBorder),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  final ListingModel listing;
  const _ListingRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    final shortId =
        listing.id.length > 8 ? listing.id.substring(0, 8) : listing.id;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kColorBorder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(PhosphorIconsLight.package,
                color: AppColors.kColorMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#$shortId',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.kColorMuted)),
                    const SizedBox(width: 8),
                    Text(listing.sellerName,
                        style: AppTextStyles.body,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.category.name} · ${listing.weight.toStringAsFixed(1)} kg · ${formatDate(listing.createdAt)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.kColorMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: listing.status),
        ],
      ),
    );
  }
}
