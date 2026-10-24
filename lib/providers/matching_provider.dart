import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/models/farmer_model.dart';
import '../data/models/match_result_model.dart';
import '../domain/matching_service.dart';
import 'listing_provider.dart';
import 'notification_provider.dart';

/// Provider untuk pencocokan limbah-ke-peternak.
class MatchingProvider extends ChangeNotifier {
  final MatchingService _matchingService;
  final ListingProvider _listingProvider;
  final NotificationProvider? _notificationProvider;

  List<MatchResultModel> _matches = [];
  List<MatchResultModel> _marketplaceListings = [];
  bool _isLoading = false;
  String? _error;

  MatchingProvider(
    this._matchingService,
    this._listingProvider, {
    NotificationProvider? notificationProvider,
  }) : _notificationProvider = notificationProvider;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MatchResultModel> get allMatches {
    final sorted = List<MatchResultModel>.from(_matches)
      ..sort((a, b) => b.score.compareTo(a.score));
    return List.unmodifiable(sorted);
  }

  /// Seluruh produk aktif yang bisa ditemukan dan dibeli di Marketplace.
  List<MatchResultModel> get marketplaceListings =>
      List.unmodifiable(_marketplaceListings);

  /// Hanya Instant Match: skor >= threshold.
  List<MatchResultModel> get instantMatches => _matches
      .where((m) => m.score >= AppConstants.kInstantMatchThreshold)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  // ---------------------------------------------------------------------------
  // Compute
  // ---------------------------------------------------------------------------

  /// Hitung semua kecocokan untuk seorang peternak dari activeListings.
  Future<void> computeMatches(FarmerModel farmer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final previousIds = _matches.map((m) => m.listing.id).toSet();
      final newMatches = _matchingService.findMatchesForFarmer(
        farmer,
        _listingProvider.activeListings,
      );
      _matches = newMatches;
      _marketplaceListings = _matchingService.scoreMarketplaceListings(
        farmer,
        _listingProvider.activeListings,
      );
      if (_notificationProvider != null && previousIds.isNotEmpty) {
        for (final m in newMatches) {
          if (!previousIds.contains(m.listing.id)) {
            _notificationProvider!.add(
              title: 'Match Baru!',
              message:
                  '${m.listing.wasteName} (${m.listing.weight} kg) cocok untuk ternak Anda.',
              type: 'match',
            );
          }
        }
      }
    } catch (e) {
      _error = 'Gagal menghitung kecocokan. Silakan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMatches() {
    _matches = [];
    _marketplaceListings = [];
    notifyListeners();
  }
}
