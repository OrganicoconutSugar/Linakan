import '../core/constants/app_constants.dart';
import '../core/utils/currency_formatter.dart' as currency_formatter;
import '../data/models/waste_category.dart';

/// Hasil harga yang disarankan.
class PriceSuggestion {
  final int basePrice;
  final double weightMultiplier;
  final String weightTier;
  final int pricePerKg;
  final int totalPrice;

  const PriceSuggestion({
    required this.basePrice,
    required this.weightMultiplier,
    required this.weightTier,
    required this.pricePerKg,
    required this.totalPrice,
  });
}

/// Rincian biaya termasuk biaya platform.
class FeeBreakdown {
  final int subtotal;
  final int platformFee;
  final int total;
  final double feeRate;

  const FeeBreakdown({
    required this.subtotal,
    required this.platformFee,
    required this.total,
    required this.feeRate,
  });
}

/// Hasil validasi override harga.
class ValidationResult {
  final bool isValid;
  final String warning;
  final double variance;

  const ValidationResult({
    required this.isValid,
    required this.warning,
    required this.variance,
  });
}

/// Layanan perhitungan harga limbah.
/// Pure Dart — tidak ada import Flutter.
class PricingService {
  // --- Harga dasar per kg (IDR) ---
  static const Map<WasteCategory, int> basePrices = {
    WasteCategory.rotiKering: 6000,
    WasteCategory.tepungAfkir: 5000,
    WasteCategory.sisaMakananOlahan: 8000,
    WasteCategory.sayuranMentah: 4000,
  };

  // --- Faktor pengali berdasarkan berat ---
  // Catatan: double.infinity valid dalam const di Dart 2.12+
  static const List<_WeightTier> _weightTiers = [
    _WeightTier(label: 'light', min: 0, max: 5, multiplier: 1.0),
    _WeightTier(label: 'medium', min: 5, max: 20, multiplier: 0.95),
    _WeightTier(label: 'heavy', min: 20, max: 50, multiplier: 0.90),
    _WeightTier(
      label: 'bulk',
      min: 50,
      max: double.infinity,
      multiplier: 0.85,
    ),
  ];

  /// Hitung harga yang disarankan berdasarkan kategori dan berat.
  PriceSuggestion calculateSuggestedPrice(
    WasteCategory category,
    double weight,
  ) {
    final basePrice = basePrices[category] ?? 5000;
    final tier = _weightTiers.firstWhere(
      (t) => weight >= t.min && weight < t.max,
      orElse: () => _weightTiers.last,
    );

    final adjustedPrice = (basePrice * tier.multiplier).round();
    final totalPrice = (adjustedPrice * weight).round();

    return PriceSuggestion(
      basePrice: basePrice,
      weightMultiplier: tier.multiplier,
      weightTier: tier.label,
      pricePerKg: adjustedPrice,
      totalPrice: totalPrice,
    );
  }

  /// Hitung total setelah ditambah biaya platform (5%).
  FeeBreakdown calculateWithFee(int totalPrice) {
    final platformFee = (totalPrice * AppConstants.kPlatformFeeRate).round();
    return FeeBreakdown(
      subtotal: totalPrice,
      platformFee: platformFee,
      total: totalPrice + platformFee,
      feeRate: AppConstants.kPlatformFeeRate,
    );
  }

  /// Validasi override harga oleh penjual. Tolak jika variance > ±50%.
  ValidationResult validatePriceOverride(int suggested, int override) {
    final variance = ((override - suggested) / suggested) * 100;

    if (variance.abs() > 50) {
      return ValidationResult(
        isValid: false,
        warning:
            'Harga yang diajukan terlalu berbeda dari rekomendasi. Maksimal ±50%.',
        variance: variance,
      );
    }
    if (variance < -30) {
      return ValidationResult(
        isValid: true,
        warning: 'Harga Anda jauh lebih rendah dari rekomendasi.',
        variance: variance,
      );
    }
    if (variance > 30) {
      return ValidationResult(
        isValid: true,
        warning: 'Harga Anda jauh lebih tinggi dari rekomendasi.',
        variance: variance,
      );
    }
    return ValidationResult(isValid: true, warning: '', variance: variance);
  }

  /// Jumlah yang harus dibayar peternak (harga + biaya platform).
  int calculateFarmerCheckout(int price) {
    return calculateWithFee(price).total;
  }

  /// Jumlah yang diterima penjual (harga - biaya platform).
  int calculateSellerEarnings(int price) {
    final fee = calculateWithFee(price);
    return price - fee.platformFee;
  }

  /// Utility format Rupiah.
  String formatRupiah(int amount) => currency_formatter.formatRupiah(amount);
}

/// Data kelas internal untuk tier berat.
class _WeightTier {
  final String label;
  final double min;
  final double max;
  final double multiplier;

  const _WeightTier({
    required this.label,
    required this.min,
    required this.max,
    required this.multiplier,
  });
}
