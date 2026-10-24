import 'dart:math';

/// Hasil operasi auth.
class AuthResult {
  final bool success;
  final String? error;
  final String? userId;

  const AuthResult({required this.success, this.error, this.userId});
}

/// Layanan autentikasi simulasi LINAKAN.
/// OTP digenerate secara lokal (6 digit) — tidak ada pengiriman SMS nyata.
/// Semua state disimpan in-memory per sesi.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Simpan OTP aktif: phone -> kode
  final Map<String, String> _otpStore = {};

  // Waktu kirim OTP terakhir: phone -> DateTime
  final Map<String, DateTime> _otpSentAt = {};

  // Durasi OTP valid (5 menit)
  static const Duration _otpTtl = Duration(minutes: 5);

  // --- OTP ---

  /// Generate dan "kirim" OTP ke nomor hp (simulasi).
  /// Return kode OTP agar UI bisa tampilkan sebagai demo.
  String generateOtp(String phone) {
    final code = (100000 + Random().nextInt(900000)).toString();
    _otpStore[_normalizePhone(phone)] = code;
    _otpSentAt[_normalizePhone(phone)] = DateTime.now();
    return code;
  }

  /// Verifikasi OTP yang diinput user.
  bool verifyOtp(String phone, String inputCode) {
    final key = _normalizePhone(phone);
    final stored = _otpStore[key];
    final sentAt = _otpSentAt[key];
    if (stored == null || sentAt == null) return false;
    if (DateTime.now().difference(sentAt) > _otpTtl) {
      _otpStore.remove(key);
      _otpSentAt.remove(key);
      return false;
    }
    final valid = stored == inputCode.trim();
    if (valid) {
      _otpStore.remove(key);
      _otpSentAt.remove(key);
    }
    return valid;
  }

  /// Apakah ada OTP aktif untuk nomor ini.
  bool hasActiveOtp(String phone) {
    final key = _normalizePhone(phone);
    final sentAt = _otpSentAt[key];
    if (sentAt == null) return false;
    return DateTime.now().difference(sentAt) <= _otpTtl;
  }

  /// Sisa detik sebelum OTP expired (untuk countdown UI).
  int otpSecondsRemaining(String phone) {
    final key = _normalizePhone(phone);
    final sentAt = _otpSentAt[key];
    if (sentAt == null) return 0;
    final elapsed = DateTime.now().difference(sentAt);
    final remaining = _otpTtl - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  // --- Validasi input ---

  /// Validasi format nomor HP Indonesia.
  /// Diterima: 08xx, +628xx, 628xx (minimal 10 digit, max 13).
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    final cleaned = phone.replaceAll(RegExp(r'\s|-'), '');
    final pattern = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Masukkan nomor HP yang valid (contoh: 08123456789)';
    }
    return null;
  }

  /// Validasi password: minimal 6 karakter.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validasi nama lengkap.
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Nama tidak boleh kosong';
    if (name.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // --- Normalisasi ---

  /// Normalkan nomor hp ke format 08xx untuk dipakai sebagai key.
  static String normalizePhone(String phone) => _normalizePhone(phone);

  static String _normalizePhone(String phone) {
    String p = phone.replaceAll(RegExp(r'\s|-'), '');
    if (p.startsWith('+62')) p = '0${p.substring(3)}';
    if (p.startsWith('62')) p = '0${p.substring(2)}';
    return p;
  }
}
