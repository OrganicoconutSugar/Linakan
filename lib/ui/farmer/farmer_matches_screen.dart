import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/matching_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/empty_state.dart';
import '../common/widgets/match_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Layar Instant Match peternak — daftar listing dengan skor >= 85.
class FarmerMatchesScreen extends StatefulWidget {
  const FarmerMatchesScreen({super.key});

  @override
  State<FarmerMatchesScreen> createState() => _FarmerMatchesScreenState();
}

class _FarmerMatchesScreenState extends State<FarmerMatchesScreen> {
  int _currentNavIndex = 1;
  bool _showAll = false; // false = Instant Match, true = Semua Cocok

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureMatches());
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

  @override
  Widget build(BuildContext context) {
    final matchingProvider = context.watch<MatchingProvider>();
    final instantMatches = matchingProvider.instantMatches;
    final allMatches = matchingProvider.allMatches;

    final displayed = _showAll ? allMatches : instantMatches;
    final badgeCount = instantMatches.length;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Instant Match', style: AppTextStyles.heading3),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.kColorSuccess,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badgeCount',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.kColorOnPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.kColorSurface,
        foregroundColor: AppColors.kColorText,
        elevation: 0,
      ),
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        userType: UserType.farmer,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.kColorBackground,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Instant Match'),
                  selected: !_showAll,
                  onSelected: (_) => setState(() => _showAll = false),
                  selectedColor: AppColors.kColorSuccess,
                  labelStyle: TextStyle(
                    color: !_showAll
                        ? AppColors.kColorOnPrimary
                        : AppColors.kColorText,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.kColorSurface,
                  side: const BorderSide(color: AppColors.kColorBorder),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Semua Cocok'),
                  selected: _showAll,
                  onSelected: (_) => setState(() => _showAll = true),
                  selectedColor: AppColors.kColorPrimary,
                  labelStyle: TextStyle(
                    color: _showAll
                        ? AppColors.kColorOnPrimary
                        : AppColors.kColorText,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.kColorSurface,
                  side: const BorderSide(color: AppColors.kColorBorder),
                ),
              ],
            ),
          ),
          // Daftar
          Expanded(
            child: displayed.isEmpty
                ? ListView(
                    children: [
                      EmptyState(
                        icon: PhosphorIconsLight.lightning,
                        title: _showAll
                            ? 'Belum ada kecocokan.'
                            : 'Belum ada Instant Match.',
                        subtitle: _showAll
                            ? 'Coba ubah filter atau periksa kembali nanti.'
                            : 'Perbarui profil Anda atau tunggu listing baru.',
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _ensureMatches,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: displayed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final match = displayed[index];
                        return MatchCard(
                          matchResult: match,
                          onDetailPressed: () =>
                              context.go('/farmer/listing/${match.listing.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
