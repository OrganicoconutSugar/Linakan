import 'package:flutter_test/flutter_test.dart';
import 'package:linakan_app/data/models/listing_model.dart';
import 'package:linakan_app/data/models/listing_status.dart';
import 'package:linakan_app/data/models/waste_category.dart';
import 'package:linakan_app/domain/shelf_life_service.dart';

void main() {
  late ShelfLifeService service;

  setUp(() {
    service = ShelfLifeService();
  });

  group('getShelfLifeHours', () {
    test('rotiKering = 336 jam', () {
      expect(service.getShelfLifeHours(WasteCategory.rotiKering), equals(336));
    });

    test('tepungAfkir = 336 jam', () {
      expect(service.getShelfLifeHours(WasteCategory.tepungAfkir), equals(336));
    });

    test('sisaMakananOlahan = 24 jam', () {
      expect(
        service.getShelfLifeHours(WasteCategory.sisaMakananOlahan),
        equals(24),
      );
    });

    test('sayuranMentah = 48 jam', () {
      expect(
        service.getShelfLifeHours(WasteCategory.sayuranMentah),
        equals(48),
      );
    });
  });

  group('getExpiryDate', () {
    test('rotiKering kadaluarsa 336 jam setelah dibuat', () {
      final now = DateTime.now();
      final expiry = service.getExpiryDate(WasteCategory.rotiKering, now);
      expect(expiry, equals(now.add(const Duration(hours: 336))));
    });

    test('sayuranMentah kadaluarsa 48 jam setelah dibuat', () {
      final now = DateTime.now();
      final expiry = service.getExpiryDate(WasteCategory.sayuranMentah, now);
      expect(expiry, equals(now.add(const Duration(hours: 48))));
    });
  });

  group('isExpired', () {
    test('belum kadaluarsa jika baru dibuat', () {
      final now = DateTime.now();
      expect(service.isExpired(WasteCategory.rotiKering, now), isFalse);
    });

    test('kadaluarsa jika dibuat lebih dari 336 jam lalu (rotiKering)', () {
      final createdAt =
          DateTime.now().subtract(const Duration(hours: 337));
      expect(service.isExpired(WasteCategory.rotiKering, createdAt), isTrue);
    });

    test('kadaluarsa jika dibuat lebih dari 48 jam lalu (sayuranMentah)', () {
      final createdAt =
          DateTime.now().subtract(const Duration(hours: 49));
      expect(
        service.isExpired(WasteCategory.sayuranMentah, createdAt),
        isTrue,
      );
    });

    test('belum kadaluarsa jika dibuat 47 jam lalu (sayuranMentah)', () {
      final createdAt =
          DateTime.now().subtract(const Duration(hours: 47));
      expect(
        service.isExpired(WasteCategory.sayuranMentah, createdAt),
        isFalse,
      );
    });
  });

  group('filterActiveListings', () {
    ListingModel makeListing(
      String id,
      WasteCategory category,
      DateTime createdAt,
    ) {
      return ListingModel(
        id: id,
        sellerId: 'seller1',
        sellerName: 'Test Seller',
        sellerType: 'bakery',
        wasteName: 'Test',
        category: category,
        weight: 5,
        pricePerKg: 5000,
        totalPrice: 25000,
        suggestedPrice: 5000,
        finalPrice: 25000,
        location: 'Jakarta',
        lat: -6.2,
        lng: 106.8,
        pickupAddress: 'Jl. Test',
        createdAt: createdAt,
        status: ListingStatus.available,
        quality: 'Baik',
      );
    }

    test('menghapus listing yang sudah kadaluarsa', () {
      final now = DateTime.now();
      final listings = [
        makeListing(
          'l1',
          WasteCategory.rotiKering,
          now.subtract(const Duration(hours: 10)), // masih aktif
        ),
        makeListing(
          'l2',
          WasteCategory.sayuranMentah,
          now.subtract(const Duration(hours: 49)), // kadaluarsa
        ),
        makeListing(
          'l3',
          WasteCategory.tepungAfkir,
          now.subtract(const Duration(hours: 20)), // masih aktif
        ),
      ];

      final active = service.filterActiveListings(listings);
      expect(active.length, equals(2));
      expect(active.map((l) => l.id), containsAll(['l1', 'l3']));
      expect(active.map((l) => l.id), isNot(contains('l2')));
    });
  });
}
