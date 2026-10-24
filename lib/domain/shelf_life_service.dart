import '../core/utils/date_formatter.dart' as df;
import '../data/models/listing_model.dart';
import '../data/models/waste_category.dart';

/// Status kelayakan berdasarkan masa simpan.
enum ShelfLifeStatus {
  fresh,
  expiringSoon,
  expired,
}

/// Layanan perhitungan masa simpan limbah pangan.
/// Pure Dart — tidak ada import Flutter.
class ShelfLifeService {
  /// Mengembalikan masa simpan dalam jam untuk kategori tertentu.
  int getShelfLifeHours(WasteCategory category) {
    return category.shelfLifeHours;
  }

  /// Menghitung tanggal kadaluarsa berdasarkan kategori dan waktu buat.
  DateTime getExpiryDate(WasteCategory category, DateTime createdAt) {
    return createdAt.add(Duration(hours: category.shelfLifeHours));
  }

  /// Mengembalikan true jika listing sudah melewati masa simpannya.
  bool isExpired(WasteCategory category, DateTime createdAt) {
    return DateTime.now().isAfter(getExpiryDate(category, createdAt));
  }

  /// Mengembalikan status masa simpan: fresh / expiringSoon / expired.
  ShelfLifeStatus getStatus(WasteCategory category, DateTime createdAt) {
    final expiry = getExpiryDate(category, createdAt);
    final now = DateTime.now();
    final remaining = expiry.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return ShelfLifeStatus.expired;
    }
    // Expiring soon = tersisa ≤ 12 jam ATAU tersisa ≤ 1 hari
    if (remaining.inHours <= 24) {
      return ShelfLifeStatus.expiringSoon;
    }
    return ShelfLifeStatus.fresh;
  }

  /// Format sisa waktu menjadi teks Bahasa Indonesia.
  String formatTimeRemaining(Duration duration) {
    return df.formatTimeRemaining(duration);
  }

  /// Menghitung progress kadaluarsa: 0.0 (baru dibuat) → 1.0 (kadaluarsa).
  double getExpiryProgress(WasteCategory category, DateTime createdAt) {
    final totalHours = category.shelfLifeHours;
    final expiry = getExpiryDate(category, createdAt);
    final remaining = expiry.difference(DateTime.now());
    final usedHours = totalHours - remaining.inHours;
    final progress = usedHours / totalHours;
    return progress.clamp(0.0, 1.0).toDouble();
  }

  /// Filter listings yang masih aktif (belum kadaluarsa).
  List<ListingModel> filterActiveListings(List<ListingModel> listings) {
    return listings.where((l) => !isExpired(l.category, l.createdAt)).toList();
  }
}
