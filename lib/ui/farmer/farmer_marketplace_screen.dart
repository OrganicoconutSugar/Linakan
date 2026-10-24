import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/anim.dart';
import '../../data/models/match_result_model.dart';
import '../../../data/models/waste_category.dart';
import '../../../data/repositories/farmer_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/listing_provider.dart';
import '../../../providers/matching_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/listing_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Urutan sortir pasar.
enum _SortMode { terbaik, hargaTerendah, terdekat }

/// Layar Pasar Limbah peternak — seluruh listing aktif. Skor kecocokan tetap
/// ditampilkan sebagai bantuan memilih, tanpa membatasi produk yang terlihat.
class FarmerMarketplaceScreen extends StatefulWidget {
  const FarmerMarketplaceScreen({super.key});

  @override
  State<FarmerMarketplaceScreen> createState() =>
      _FarmerMarketplaceScreenState();
}

class _FarmerMarketplaceScreenState extends State<FarmerMarketplaceScreen> {
  int _currentNavIndex = 2;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WasteCategory? _categoryFilter; // null = semua
  _SortMode _sortMode = _SortMode.terbaik;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureMatches());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureMatches() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;
    final listingProvider = context.read<ListingProvider>();
    final matchingProvider = context.read<MatchingProvider>();
    final farmerRepository = context.read<FarmerRepository>();
    await listingProvider.loadAll();
    final farmer = farmerRepository.getById(userId);
    if (farmer != null) {
      await matchingProvider.computeMatches(farmer);
    }
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

  List<MatchResultModel> _applyFilters(List<MatchResultModel> matches) {
    final query = _searchQuery.trim().toLowerCase();
    var result = matches.where((m) {
      if (_categoryFilter != null && m.listing.category != _categoryFilter) {
        return false;
      }
      if (query.isNotEmpty &&
          !m.listing.wasteName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sortMode) {
      case _SortMode.terbaik:
        result.sort((a, b) => b.score.compareTo(a.score));
        break;
      case _SortMode.hargaTerendah:
        result.sort(
            (a, b) => a.listing.finalPrice.compareTo(b.listing.finalPrice));
        break;
      case _SortMode.terdekat:
        result.sort((a, b) => a.distance.compareTo(b.distance));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final matchingProvider = context.watch<MatchingProvider>();
    final marketplaceListings = matchingProvider.marketplaceListings;
    final displayed = _applyFilters(marketplaceListings);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: const Text('Pasar Limbah'),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        userType: UserType.farmer,
      ),
      body: RefreshIndicator(
        onRefresh: _ensureMatches,
        child: Column(
          children: [
            // Pencarian + sortir
            _buildSearchAndSort(),
            // Filter kategori
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _categoryChip('Semua', null),
                  _categoryChip('Roti Kering', WasteCategory.rotiKering),
                  _categoryChip('Tepung Afkir', WasteCategory.tepungAfkir),
                  _categoryChip(
                      'Sisa Makanan', WasteCategory.sisaMakananOlahan),
                  _categoryChip('Sayuran Mentah', WasteCategory.sayuranMentah),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Grid listing
            Expanded(
              child: Builder(builder: (context) {
                final matchingProvider = context.watch<MatchingProvider>();
                if (matchingProvider.isLoading && displayed.isEmpty) {
                  return _buildShimmerGrid();
                }
                if (displayed.isEmpty) {
                  return ListView(
                    children: const [
                      EmptyState(
                        icon: PhosphorIconsLight.storefront,
                        title: 'Tidak ada listing ditemukan.',
                        subtitle: 'Coba ubah pencarian atau filter kategori.',
                      ),
                    ],
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _columnCount(constraints.maxWidth);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 410,
                      ),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) {
                        final match = displayed[index];
                        return FadeSlideIn(
                          delay: Anim.stagger(index, base: 80),
                          child: ListingCard(
                            listing: match.listing,
                            matchResult: match,
                            onDetailPressed: () => context
                                .go('/farmer/listing/${match.listing.id}'),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final searchField = TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Cari limbah...',
            prefixIcon: const Icon(
              PhosphorIconsLight.magnifyingGlass,
              color: AppColors.kColorMuted,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.kColorSurfaceCard,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.kColorBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.kColorBorder),
            ),
          ),
        );
        final sortField = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppSurfaces.ivory,
            boxShadow: AppSurfaces.raisedShadow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.kColorBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_SortMode>(
              value: _sortMode,
              isDense: true,
              isExpanded: compact,
              items: const [
                DropdownMenuItem(
                  value: _SortMode.terbaik,
                  child: Text('Terbaik'),
                ),
                DropdownMenuItem(
                  value: _SortMode.hargaTerendah,
                  child: Text('Harga Terendah'),
                ),
                DropdownMenuItem(
                  value: _SortMode.terdekat,
                  child: Text('Terdekat'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sortMode = value);
              },
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    sortField,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    sortField,
                  ],
                ),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  Widget _buildShimmerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCount(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 380,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 200, radius: 16),
              SizedBox(height: 12),
              ShimmerBox(height: 16, width: 100, radius: 6),
              SizedBox(height: 8),
              ShimmerBox(height: 20, width: 140, radius: 6),
              SizedBox(height: 8),
              ShimmerBox(height: 36, radius: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryChip(String label, WasteCategory? category) {
    final selected = _categoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = category),
        selectedColor: AppColors.kColorPrimary,
        labelStyle: TextStyle(
          color: selected ? AppColors.kColorOnPrimary : AppColors.kColorText,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.kColorSurface,
        side: const BorderSide(color: AppColors.kColorBorder),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip)),
      ),
    );
  }
}
