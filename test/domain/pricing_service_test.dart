import 'package:flutter_test/flutter_test.dart';
import 'package:linakan_app/core/constants/app_constants.dart';
import 'package:linakan_app/data/models/waste_category.dart';
import 'package:linakan_app/domain/pricing_service.dart';

void main() {
  late PricingService service;

  setUp(() {
    service = PricingService();
  });

  group('calculateSuggestedPrice', () {
    test('10 kg rotiKering menggunakan multiplier 0.95 (tier medium)', () {
      final result =
          service.calculateSuggestedPrice(WasteCategory.rotiKering, 10);
      // basePrice = 6000, multiplier = 0.95 (5–20 kg)
      expect(result.weightMultiplier, equals(0.95));
      expect(result.pricePerKg, equals((6000 * 0.95).round())); // 5700
      expect(result.totalPrice, equals((5700 * 10).round())); // 57000
    });

    test('3 kg rotiKering menggunakan multiplier 1.0 (tier light)', () {
      final result =
          service.calculateSuggestedPrice(WasteCategory.rotiKering, 3);
      expect(result.weightMultiplier, equals(1.0));
      expect(result.pricePerKg, equals(6000));
    });

    test('25 kg tepungAfkir menggunakan multiplier 0.90 (tier heavy)', () {
      final result =
          service.calculateSuggestedPrice(WasteCategory.tepungAfkir, 25);
      expect(result.weightMultiplier, equals(0.90));
      expect(result.pricePerKg, equals((5000 * 0.90).round())); // 4500
    });
  });

  group('calculateWithFee', () {
    test('biaya platform tepat 5% dari total harga', () {
      const price = 100000;
      final breakdown = service.calculateWithFee(price);
      expect(breakdown.platformFee, equals((price * AppConstants.kPlatformFeeRate).round()));
      expect(breakdown.total, equals(price + breakdown.platformFee));
    });

    test('total = subtotal + 5% untuk berbagai harga', () {
      for (final price in [60000, 80000, 150000]) {
        final breakdown = service.calculateWithFee(price);
        expect(breakdown.total, equals(price + (price * 0.05).round()));
      }
    });
  });

  group('validatePriceOverride', () {
    test('valid jika override dalam ±50%', () {
      final result = service.validatePriceOverride(10000, 14000); // +40%
      expect(result.isValid, isTrue);
    });

    test('ditolak jika override > +50%', () {
      final result = service.validatePriceOverride(10000, 15001); // >50%
      expect(result.isValid, isFalse);
    });

    test('ditolak jika override < -50%', () {
      final result = service.validatePriceOverride(10000, 4999); // <-50%
      expect(result.isValid, isFalse);
    });

    test('valid tepat di batas 50%', () {
      final result = service.validatePriceOverride(10000, 15000); // +50%
      expect(result.isValid, isTrue);
    });

    test('valid tepat di batas -50%', () {
      final result = service.validatePriceOverride(10000, 5000); // -50%
      expect(result.isValid, isTrue);
    });
  });

  group('calculateFarmerCheckout dan calculateSellerEarnings', () {
    test('farmerPays = harga + fee platform', () {
      const price = 100000;
      expect(
        service.calculateFarmerCheckout(price),
        equals(service.calculateWithFee(price).total),
      );
    });

    test('sellerEarnings = harga - fee platform', () {
      const price = 100000;
      final fee = service.calculateWithFee(price).platformFee;
      expect(service.calculateSellerEarnings(price), equals(price - fee));
    });
  });
}
