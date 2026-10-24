import '../../core/constants/app_constants.dart';

/// Kategori limbah pangan yang dapat didaftarkan di LINAKAN.
enum WasteCategory {
  rotiKering,
  tepungAfkir,
  sisaMakananOlahan,
  sayuranMentah,
}

/// Ekstensi untuk metadata tiap kategori limbah.
extension WasteCategoryExtension on WasteCategory {
  /// ID string sesuai data.js / backend.
  String get id {
    switch (this) {
      case WasteCategory.rotiKering:
        return 'roti_kering';
      case WasteCategory.tepungAfkir:
        return 'tepung_afkir';
      case WasteCategory.sisaMakananOlahan:
        return 'sisa_makanan_olahan';
      case WasteCategory.sayuranMentah:
        return 'sayuran_mentah';
    }
  }

  /// Nama tampilan Bahasa Indonesia.
  String get name {
    switch (this) {
      case WasteCategory.rotiKering:
        return 'Roti Kering';
      case WasteCategory.tepungAfkir:
        return 'Tepung Afkir';
      case WasteCategory.sisaMakananOlahan:
        return 'Sisa Makanan Olahan';
      case WasteCategory.sayuranMentah:
        return 'Sayuran Mentah';
    }
  }

  /// Masa simpan dalam jam (dari AppConstants).
  int get shelfLifeHours {
    switch (this) {
      case WasteCategory.rotiKering:
        return AppConstants.kShelfLifeRotiKeringHours;
      case WasteCategory.tepungAfkir:
        return AppConstants.kShelfLifeTepungAfkirHours;
      case WasteCategory.sisaMakananOlahan:
        return AppConstants.kShelfLifeSisaMakananHours;
      case WasteCategory.sayuranMentah:
        return AppConstants.kShelfLifeSayuranMentahHours;
    }
  }

  /// Ternak yang kompatibel dengan kategori ini.
  List<String> get compatibleLivestock {
    switch (this) {
      case WasteCategory.rotiKering:
        return ['ayam', 'bebek', 'unggas_lainnya'];
      case WasteCategory.tepungAfkir:
        return ['ayam', 'bebek', 'unggas_lainnya'];
      case WasteCategory.sisaMakananOlahan:
        return ['ayam', 'bebek', 'babi', 'sapi'];
      case WasteCategory.sayuranMentah:
        return ['sapi', 'kambing', 'kelinci'];
    }
  }

  /// Parse dari string ID.
  static WasteCategory fromId(String id) {
    switch (id) {
      case 'roti_kering':
        return WasteCategory.rotiKering;
      case 'tepung_afkir':
        return WasteCategory.tepungAfkir;
      case 'sisa_makanan_olahan':
        return WasteCategory.sisaMakananOlahan;
      case 'sayuran_mentah':
        return WasteCategory.sayuranMentah;
      default:
        throw ArgumentError('Kategori tidak dikenal: $id');
    }
  }
}
