import '../core/constants/app_constants.dart';
import '../core/utils/haversine.dart';
import '../data/models/farmer_model.dart';
import '../data/models/listing_model.dart';
import '../data/models/listing_status.dart';
import '../data/models/match_result_model.dart';
import '../data/models/waste_category.dart';
import 'shelf_life_service.dart';

/// Layanan pencocokan limbah-ke-peternak.
/// Pure Dart — tidak ada import Flutter.
class MatchingService {
  final ShelfLifeService _shelfLifeService;

  MatchingService(this._shelfLifeService);

  // ---------------------------------------------------------------------------
  // Private scoring helpers
  // ---------------------------------------------------------------------------

  /// Skor kategori: 100 jika ada satu ternak yang kompatibel, 0 jika tidak.
  /// Jika listing memiliki customCategory, skor 100 (universal).
  int _categoryScore(ListingModel listing, FarmerModel farmer) {
    if (listing.customCategory != null && listing.customCategory!.isNotEmpty) {
      return 100;
    }
    final compatible = listing.category.compatibleLivestock;
    final hasMatch = farmer.livestock.any((lt) => compatible.contains(lt));
    return hasMatch ? 100 : 0;
  }

  /// Skor lokasi berdasarkan jarak Haversine.
  /// 100 jika ≤ 5 km, menurun linier hingga 0 di 15 km, 0 jika > 15 km.
  int _locationScore(ListingModel listing, FarmerModel farmer) {
    final distance = calculateDistanceKm(
      listing.lat,
      listing.lng,
      farmer.lat,
      farmer.lng,
    );
    if (distance <= 5.0) return 100;
    if (distance <= AppConstants.kMaxMatchRadius) {
      return (100 *
              (AppConstants.kMaxMatchRadius - distance) /
              (AppConstants.kMaxMatchRadius - 5.0))
          .round();
    }
    return 0;
  }

  /// Skor kapasitas: seberapa baik berat listing cocok dengan kapasitas peternak.
  int _capacityScore(ListingModel listing, FarmerModel farmer) {
    final threshold = farmer.capacity * 0.5; // 50% dari kapasitas mingguan
    if (threshold <= 0 || listing.weight <= 0) return 0;
    if (listing.weight <= threshold) {
      return ((listing.weight / threshold) * 100).round().clamp(0, 100).toInt();
    }
    return ((threshold / listing.weight) * 100).round().clamp(0, 100).toInt();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Hitung skor kompatibilitas untuk satu pasang listing–peternak.
  MatchResultModel calculateCompatibility(
    ListingModel listing,
    FarmerModel farmer,
  ) {
    // Listing kadaluarsa → skor 0
    if (_shelfLifeService.isExpired(listing.category, listing.createdAt)) {
      return MatchResultModel(
        listing: listing,
        score: 0,
        isInstantMatch: false,
        expired: true,
        categoryScore: 0,
        locationScore: 0,
        capacityScore: 0,
        distance: calculateDistanceKm(
          listing.lat,
          listing.lng,
          farmer.lat,
          farmer.lng,
        ),
        capacityPercentage: 0,
      );
    }

    final catScore = _categoryScore(listing, farmer);
    final locScore = _locationScore(listing, farmer);
    final capScore = _capacityScore(listing, farmer);

    final distance = calculateDistanceKm(
      listing.lat,
      listing.lng,
      farmer.lat,
      farmer.lng,
    );

    final score = (catScore * AppConstants.kWeightCategory +
            locScore * AppConstants.kWeightLocation +
            capScore * AppConstants.kWeightCapacity)
        .round();

    final compatible = listing.category.compatibleLivestock;
    final matchingLivestock =
        farmer.livestock.where((lt) => compatible.contains(lt)).toList();
    final reasons = catScore > 0
        ? ['Cocok untuk ternak: ${matchingLivestock.join(", ")}']
        : ['${listing.category.name} tidak cocok untuk ternak Anda'];

    final capacityPercentage = farmer.capacity > 0
        ? ((listing.weight / farmer.capacity) * 100).round()
        : 0;

    return MatchResultModel(
      listing: listing,
      score: score,
      isInstantMatch: score >= AppConstants.kInstantMatchThreshold,
      expired: false,
      categoryScore: catScore,
      locationScore: locScore,
      capacityScore: capScore,
      distance: distance,
      categoryReasons: reasons,
      capacityPercentage: capacityPercentage,
    );
  }

  /// Cari semua listing yang cocok untuk seorang peternak.
  /// - Filter: status available, tidak kadaluarsa, jarak ≤ 15 km.
  /// - Urutan: skor DESC.
  List<MatchResultModel> findMatchesForFarmer(
    FarmerModel farmer,
    List<ListingModel> listings,
  ) {
    final activeListings = listings
        .where((l) => l.status == ListingStatus.available)
        .where(
          (l) => !_shelfLifeService.isExpired(l.category, l.createdAt),
        )
        .toList();

    final matches = activeListings
        .map((l) => calculateCompatibility(l, farmer))
        .where(
          (m) =>
              m.score > 0 &&
              !m.expired &&
              m.distance <= AppConstants.kMaxMatchRadius,
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return matches;
  }

  /// Nilai seluruh listing aktif untuk katalog Marketplace.
  /// Jarak dan kecocokan memengaruhi skor, tetapi tidak menyembunyikan produk.
  List<MatchResultModel> scoreMarketplaceListings(
    FarmerModel farmer,
    List<ListingModel> listings,
  ) {
    final results = listings
        .where((l) => l.status == ListingStatus.available)
        .where((l) => !_shelfLifeService.isExpired(l.category, l.createdAt))
        .map((l) => calculateCompatibility(l, farmer))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Kembalikan hanya Instant Match (skor ≥ threshold).
  List<MatchResultModel> getInstantMatches(
    FarmerModel farmer,
    List<ListingModel> listings,
  ) {
    return findMatchesForFarmer(farmer, listings)
        .where((m) => m.isInstantMatch)
        .toList();
  }
}
