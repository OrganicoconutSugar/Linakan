import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/storage_service.dart';
import '../data/models/farmer_model.dart';
import '../data/models/seller_model.dart';
import '../data/repositories/farmer_repository.dart';
import '../data/repositories/seller_repository.dart';

/// Tipe pengguna yang sedang login.
enum UserType { seller, farmer, admin }

/// Hasil operasi login/register.
class AuthResult {
  final bool success;
  final String? error;
  const AuthResult({required this.success, this.error});
}

/// Provider autentikasi LINAKAN.
/// Login via nomor HP + password + OTP simulasi.
class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  late final SellerRepository _sellerRepo;
  late final FarmerRepository _farmerRepo;

  String? _currentUserId;
  UserType? _currentUserType;
  String? _pendingUserId;
  UserType? _pendingUserType;

  // Key storage untuk data akun (phone -> {password, userId, userType})
  static const String _kKeyAccounts = 'linakan_accounts';

  AuthProvider(
    this._storage, {
    required SellerRepository sellerRepo,
    required FarmerRepository farmerRepo,
  })  : _sellerRepo = sellerRepo,
        _farmerRepo = farmerRepo {
    _loadFromStorage();
    // Ensure NotificationProvider exists for tests without UI.
    // If NotificationProvider is not in MultiProvider, a dummy will be used in tests.
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  String? get currentUserId => _currentUserId;
  UserType? get currentUserType => _currentUserType;
  bool get isLoggedIn => _currentUserId != null && _currentUserType != null;

  bool get isSeller => _currentUserType == UserType.seller;
  bool get isFarmer => _currentUserType == UserType.farmer;
  bool get isAdmin => _currentUserType == UserType.admin;
  bool get isAwaitingOtp => _pendingUserId != null && _pendingUserType != null;

  /// Tujuan utama setelah login berhasil.
  /// Intro/onboarding dijalankan dari alur registrasi; akun yang sudah terdaftar
  /// selalu kembali langsung ke dashboard saat login berikutnya.
  String get authenticatedHomeRoute {
    if (isAdmin) return '/admin/dashboard';
    if (isFarmer) return '/farmer/dashboard';
    return '/seller/dashboard';
  }

  // ---------------------------------------------------------------------------
  // Login dengan nomor HP + password
  // ---------------------------------------------------------------------------

  /// Cari akun berdasarkan nomor HP dan verifikasi password.
  /// Return AuthResult — jika success, identitas ditahan sampai OTP terverifikasi.
  AuthResult loginWithEmailOrPhone(String identifier, String password) {
    final isEmail = identifier.contains('@');
    final key = isEmail ? identifier.trim() : _normalizePhone(identifier);
    final accounts = _loadAccounts();

    if (!accounts.containsKey(key)) {
      return AuthResult(
        success: false,
        error: isEmail
            ? 'Email tidak terdaftar. Silakan daftar terlebih dahulu.'
            : 'Nomor HP tidak terdaftar. Silakan daftar terlebih dahulu.',
      );
    }

    final account = accounts[key]!;
    if (account['password'] != password) {
      return const AuthResult(
        success: false,
        error: 'Password salah. Silakan coba lagi.',
      );
    }

    _beginAuthentication(
      account['userId'] as String,
      _userTypeFromStr(account['userType']),
    );
    return const AuthResult(success: true);
  }

  UserType _userTypeFromStr(String? name) => UserType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => UserType.seller,
      );

  /// Legacy: login via phone only.
  AuthResult loginWithPhone(String phone, String password) =>
      loginWithEmailOrPhone(phone, password);

  // ---------------------------------------------------------------------------
  // Register akun baru
  // ---------------------------------------------------------------------------

  /// Daftarkan akun baru dengan nomor HP, password, nama, alamat, lat/lng, role.
  /// Membuat profil seller atau farmer sesuai role yang dipilih.
  AuthResult register({
    required String phone,
    required String password,
    required String name,
    String? businessName,
    required String address,
    required double lat,
    required double lng,
    required UserType role,
    String sellerType = 'umkm', // untuk seller: irt | umkm
  }) {
    final normalized = _normalizePhone(phone);
    final accounts = _loadAccounts();

    if (accounts.containsKey(normalized)) {
      return const AuthResult(
        success: false,
        error: 'Nomor HP sudah terdaftar. Silakan masuk.',
      );
    }

    // Generate ID unik
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(9999);
    final userId = '${role.name}_${timestamp}_$rand';

    // Buat profil sesuai role
    if (role == UserType.seller) {
      final seller = SellerModel(
        id: userId,
        name: (businessName != null && businessName.trim().isNotEmpty)
            ? businessName.trim()
            : name.trim(),
        type: sellerType,
        email: '',
        phone: normalized,
        location: address.trim(),
        lat: lat,
        lng: lng,
        verified: false,
        joinDate: DateTime.now().toIso8601String().substring(0, 10),
        walletBalance: 0,
        averageRating: 0,
        totalTransactions: 0,
      );
      _sellerRepo.add(seller);
    } else if (role == UserType.farmer) {
      final farmer = FarmerModel(
        id: userId,
        name: name.trim(),
        livestock: [],
        feedRequirements: '',
        capacity: 0,
        email: '',
        phone: normalized,
        location: address.trim(),
        lat: lat,
        lng: lng,
        verified: false,
        joinDate: DateTime.now().toIso8601String().substring(0, 10),
        walletBalance: 0,
        averageRating: 0,
        totalTransactions: 0,
      );
      _farmerRepo.add(farmer);
    }

    // Simpan akun
    accounts[normalized] = {
      'userId': userId,
      'userType': role.name,
      'password': password,
    };
    _persistAccounts(accounts);

    // Tahan sesi hingga OTP berhasil diverifikasi.
    _beginAuthentication(userId, role);
    return const AuthResult(success: true);
  }

  /// Aktifkan sesi hanya setelah kode OTP dinyatakan valid oleh AuthService.
  bool completeOtpVerification() {
    final userId = _pendingUserId;
    final userType = _pendingUserType;
    if (userId == null || userType == null) return false;

    _pendingUserId = null;
    _pendingUserType = null;
    _setUser(userId, userType);
    return true;
  }

  /// Mengganti password akun pengguna yang sedang aktif.
  AuthResult changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    final userId = _currentUserId;
    if (userId == null) {
      return const AuthResult(
        success: false,
        error: 'Sesi pengguna tidak ditemukan.',
      );
    }
    if (newPassword.length < 6) {
      return const AuthResult(
        success: false,
        error: 'Password baru minimal 6 karakter.',
      );
    }

    final accounts = _loadAccounts();
    String? accountKey;
    for (final entry in accounts.entries) {
      if (entry.value['userId'] == userId) {
        accountKey = entry.key;
        break;
      }
    }
    if (accountKey == null) {
      return const AuthResult(
        success: false,
        error: 'Data akun tidak ditemukan.',
      );
    }

    final account = accounts[accountKey]!;
    if (account['password'] != currentPassword) {
      return const AuthResult(
        success: false,
        error: 'Password lama tidak sesuai.',
      );
    }
    account['password'] = newPassword;
    _persistAccounts(accounts);
    return const AuthResult(success: true);
  }

  /// Batalkan autentikasi yang belum menyelesaikan OTP.
  void cancelPendingAuthentication() {
    if (!isAwaitingOtp) return;
    _pendingUserId = null;
    _pendingUserType = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  void logout() {
    _currentUserId = null;
    _currentUserType = null;
    _pendingUserId = null;
    _pendingUserType = null;
    _storage.remove(AppConstants.kKeyCurrentUser);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _beginAuthentication(String userId, UserType userType) {
    _pendingUserId = userId;
    _pendingUserType = userType;
    notifyListeners();
  }

  void _setUser(String userId, UserType userType) {
    _currentUserId = userId;
    _currentUserType = userType;
    _persistSession();
    notifyListeners();
  }

  void _persistSession() {
    if (_currentUserId == null || _currentUserType == null) return;
    _storage.setString(
      AppConstants.kKeyCurrentUser,
      jsonEncode({
        'userId': _currentUserId,
        'userType': _currentUserType!.name,
      }),
    );
  }

  void _loadFromStorage() {
    final raw = _storage.getString(AppConstants.kKeyCurrentUser);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final userId = map['userId'] as String?;
      final userTypeStr = map['userType'] as String?;
      if (userId != null && userTypeStr != null) {
        _currentUserId = userId;
        _currentUserType = UserType.values.firstWhere(
          (e) => e.name == userTypeStr,
          orElse: () => UserType.seller,
        );
      }
    } catch (_) {}
  }

  Map<String, Map<String, dynamic>> _loadAccounts() {
    final raw = _storage.getString(_kKeyAccounts);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  void _persistAccounts(Map<String, Map<String, dynamic>> accounts) {
    _storage.setString(_kKeyAccounts, jsonEncode(accounts));
  }

  static String _normalizePhone(String phone) {
    String p = phone.replaceAll(RegExp(r'\s|-'), '');
    if (p.startsWith('+62')) p = '0${p.substring(3)}';
    if (p.startsWith('62')) p = '0${p.substring(2)}';
    return p;
  }
}
