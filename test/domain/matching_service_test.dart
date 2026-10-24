import 'package:flutter_test/flutter_test.dart';
import 'package:linakan_app/core/constants/app_constants.dart';
import 'package:linakan_app/data/models/farmer_model.dart';
import 'package:linakan_app/data/models/listing_model.dart';
import 'package:linakan_app/data/models/listing_status.dart';
import 'package:linakan_app/data/models/waste_category.dart';
import 'package:linakan_app/domain/matching_service.dart';
import 'package:linakan_app/domain/shelf_life_service.dart';

ListingModel _makeListing({
  String id = 'l1',
  WasteCategory category = WasteCategory.rotiKering,
  double weight = 10,
  double lat = -6.2297,
  double lng = 106.8419,
  ListingStatus status = ListingStatus.available,
  DateTime? createdAt,
}) {
  return ListingModel(
    id: id,
    sellerId: 'seller1',
    sellerName: 'Test Seller',
    sellerType: 'bakery',
    wasteName: 'Test',
    category: category,
    weight: weight,
    pricePerKg: 5000,
    totalPrice: 50000,
    suggestedPrice: 5000,
    finalPrice: 50000,
    location: 'Jakarta',
    lat: lat,
    lng: lng,
    pickupAddress: 'Jl. Test',
    createdAt: createdAt ?? DateTime.now(),
    status: status,
    quality: 'Baik',
  );
}

FarmerModel _makeFarmer({
  String id = 'f1',
  List<String> livestock = const ['ayam', 'bebek'],
  double capacity = 50,
  double lat = -6.2500,
  double lng = 106.8300,
}) {
  return FarmerModel(
    id: id,
    name: 'Test Farmer',
    livestock: livestock,
    feedRequirements: '-',
    capacity: capacity,
    email: 'farmer@test.id',
    phone: '+62811111111',
    location: 'Jakarta',
    lat: lat,
    lng: lng,
    verified: true,
    joinDate: '2024-01-01',
    walletBalance: 1000000,
    averageRating: 4.5,
    totalTransactions: 5,
  );
}

void main() {
  late MatchingService service;

  setUp(() {
    service = MatchingService(ShelfLifeService());
  });

  group('calculateCompatibility - categoryScore', () {
    test('skor kategori 100 jika ternak kompatibel', () {
      final listing = _makeListing(category: WasteCategory.rotiKering);
      final farmer = _makeFarmer(livestock: ['ayam']);
      final result = service.calculateCompatibility(listing, farmer);
      expect(result.categoryScore, equals(100));
    });

    test('skor kategori 0 jika ternak tidak kompatibel', () {
      // rotiKering hanya untuk ayam/bebek/unggas, bukan sapi
      final listing = _makeListing(category: WasteCategory.rotiKering);
      final farmer = _makeFarmer(livestock: ['sapi', 'kambing']);
      final result = service.calculateCompatibility(listing, farmer);
      expect(result.categoryScore, equals(0));
    });
  });

  group('calculateCompatibility - capacityScore', () {
    test('kapasitas nol tidak menyebabkan pembagian dengan nol', () {
      final listing = _makeListing(weight: 10);
      final farmer = _makeFarmer(capacity: 0);

      final result = service.calculateCompatibility(listing, farmer);

      expect(result.capacityScore, 0);
      expect(result.capacityPercentage, 0);
    });
  });

  group('calculateCompatibility - locationScore', () {
    test('skor lokasi 100 jika jarak ≤ 3 km', () {
      // Koordinat sangat dekat (~0 km)
      final listing = _makeListing(lat: -6.2297, lng: 106.8419);
      final farmer = _makeFarmer(lat: -6.2300, lng: 106.8420);
      final result = service.calculateCompatibility(listing, farmer);
      expect(result.locationScore, equals(100));
    });

    test('skor lokasi 0 jika jarak > 15 km', () {
      // Koordinat sangat jauh (> 15 km)
      final listing = _makeListing(lat: -6.2297, lng: 106.8419);
      // Depok ~14km, buat lebih jauh
      final farmer = _makeFarmer(lat: -6.50, lng: 107.00); // jauh
      final result = service.calculateCompatibility(listing, farmer);
      expect(result.locationScore, equals(0));
    });
  });

  group('isInstantMatch', () {
    test('instant match jika skor ≥ 85', () {
      // Listing rotiKering + farmer bebek/ayam + jarak dekat + kapasitas memadai
      final listing = _makeListing(
        category: WasteCategory.rotiKering,
        weight: 10,
        lat: -6.2297,
        lng: 106.8419,
      );
      final farmer = _makeFarmer(
        livestock: ['ayam', 'bebek'],
        capacity: 40, // 50% = 20 kg, weight 10 ≤ 20 → capScore > 0
        lat: -6.2400, // ~1 km
        lng: 106.8450,
      );
      final result = service.calculateCompatibility(listing, farmer);
      expect(result.isInstantMatch, isTrue);
      expect(result.score,
          greaterThanOrEqualTo(AppConstants.kInstantMatchThreshold));
    });

    test('bukan instant match jika listing kadaluarsa', () {
      final expiredListing = _makeListing(
        category: WasteCategory.sayuranMentah,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 60)), // expired
      );
      final farmer = _makeFarmer(livestock: ['sapi', 'kambing']);
      final result = service.calculateCompatibility(expiredListing, farmer);
      expect(result.isInstantMatch, isFalse);
      expect(result.score, equals(0));
      expect(result.expired, isTrue);
    });
  });

  group('findMatchesForFarmer', () {
    test('mengecualikan listing kadaluarsa', () {
      final farmer =
          _makeFarmer(livestock: ['ayam', 'bebek'], lat: -6.23, lng: 106.84);
      final listings = [
        _makeListing(
          id: 'active',
          category: WasteCategory.rotiKering,
          createdAt: DateTime.now(),
        ),
        _makeListing(
          id: 'expired',
          category: WasteCategory.sayuranMentah,
          createdAt: DateTime.now().subtract(const Duration(hours: 60)),
        ),
      ];

      final matches = service.findMatchesForFarmer(farmer, listings);
      expect(matches.map((m) => m.listing.id), isNot(contains('expired')));
    });

    test('mengecualikan listing yang berjarak > 15 km', () {
      final farmer = _makeFarmer(lat: -6.23, lng: 106.84);
      final farListing = _makeListing(
        id: 'far',
        lat: -6.70, // sangat jauh
        lng: 107.20,
      );
      final nearListing = _makeListing(
        id: 'near',
        lat: -6.24,
        lng: 106.85,
        category: WasteCategory.rotiKering,
      );

      final matches = service.findMatchesForFarmer(
        farmer,
        [farListing, nearListing],
      );
      expect(matches.map((m) => m.listing.id), isNot(contains('far')));
    });

    test('hasil diurutkan berdasarkan skor DESC', () {
      final farmer = _makeFarmer(
        livestock: ['ayam', 'bebek'],
        lat: -6.23,
        lng: 106.84,
      );
      // listing1 dekat dan kompatibel → skor tinggi
      final listing1 = _makeListing(
        id: 'l1',
        category: WasteCategory.rotiKering,
        lat: -6.24,
        lng: 106.85,
        weight: 5,
      );
      // listing2 jauh → skor rendah
      final listing2 = _makeListing(
        id: 'l2',
        category: WasteCategory.rotiKering,
        lat: -6.35,
        lng: 106.90,
        weight: 5,
      );

      final matches =
          service.findMatchesForFarmer(farmer, [listing2, listing1]);
      if (matches.length >= 2) {
        expect(matches[0].score, greaterThanOrEqualTo(matches[1].score));
      }
    });
  });

  group('scoreMarketplaceListings', () {
    test('marketplace tetap menampilkan listing aktif di luar radius match', () {
      final farmer = _makeFarmer(
        livestock: ['sapi'],
        lat: -6.23,
        lng: 106.84,
      );
      final farListing = _makeListing(
        id: 'far-active',
        category: WasteCategory.rotiKering,
        lat: -7.20,
        lng: 107.60,
      );

      final marketplace = service.scoreMarketplaceListings(
        farmer,
        [farListing],
      );

      expect(marketplace.map((m) => m.listing.id), contains('far-active'));
      expect(
        service.findMatchesForFarmer(farmer, [farListing]),
        isEmpty,
      );
    });

    test('marketplace tidak menampilkan listing habis masa simpan', () {
      final farmer = _makeFarmer();
      final expired = _makeListing(
        id: 'expired-marketplace',
        category: WasteCategory.sayuranMentah,
        createdAt: DateTime.now().subtract(const Duration(hours: 60)),
      );

      final marketplace = service.scoreMarketplaceListings(
        farmer,
        [expired],
      );

      expect(marketplace, isEmpty);
    });
  });
}
