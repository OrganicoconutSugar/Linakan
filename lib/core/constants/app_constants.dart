/// Konstanta aturan bisnis LINAKAN.
/// Semua nilai aturan bisnis wajib diambil dari sini — jangan pernah hard-code di tempat lain.
class AppConstants {
  AppConstants._();

  // --- Listing ---
  /// Berat minimum listing (kg)
  static const double kMinListingWeight = 2.0;

  // --- Matching ---
  /// Radius maksimum pencocokan (km)
  static const double kMaxMatchRadius = 15.0;

  /// Threshold skor untuk Instant Match (%)
  static const int kInstantMatchThreshold = 85;

  // --- Biaya Platform ---
  /// Tarif biaya platform (5%)
  static const double kPlatformFeeRate = 0.05;

  // --- Masa Simpan (jam) ---
  /// Masa simpan Roti Kering: 14 hari = 336 jam
  static const int kShelfLifeRotiKeringHours = 336;

  /// Masa simpan Tepung Afkir: 14 hari = 336 jam
  static const int kShelfLifeTepungAfkirHours = 336;

  /// Masa simpan Sisa Makanan Olahan: 1 hari = 24 jam
  static const int kShelfLifeSisaMakananHours = 24;

  /// Masa simpan Sayuran Mentah: 2 hari = 48 jam
  static const int kShelfLifeSayuranMentahHours = 48;

  // --- Bobot Pencocokan ---
  /// Bobot kategori dalam skor kecocokan
  static const double kWeightCategory = 0.4;

  /// Bobot lokasi dalam skor kecocokan
  static const double kWeightLocation = 0.4;

  /// Bobot kapasitas dalam skor kecocokan
  static const double kWeightCapacity = 0.2;

  // --- Storage Keys ---
  static const String kKeySellers = 'linakan_sellers';
  static const String kKeyFarmers = 'linakan_farmers';
  static const String kKeyListings = 'linakan_listings';
  static const String kKeyTransactions = 'linakan_transactions';
  static const String kKeyCurrentUser = 'linakan_current_user';
  static const String kKeyDataVersion = 'linakan_data_version';
  static const String kKeyIntroSeen =
      'linakan_intro_seen'; // flag intro sudah dilihat
  static const String kKeyRememberedPhone = 'linakan_remembered_phone';
  static const String kKeyIntroSeenFarmer = 'linakan_intro_seen_farmer';
  static const String kKeyAccounts = 'linakan_accounts';

  // Admin seed credentials
  static const String kAdminPhone = '08000000000';
  static const String kAdminEmail = 'admin@linakan.id';
  static const String kAdminPassword = 'admin123';
  static const String kAdminUserId = 'admin_1';

  /// Versi seed data — ubah jika perlu re-seed
  static const String kSeedDataVersion = 'flutter-v1';
}
