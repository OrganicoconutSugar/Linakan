import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linakan_app/core/constants/app_constants.dart';
import 'package:linakan_app/core/services/storage_service.dart';
import 'package:linakan_app/data/repositories/farmer_repository.dart';
import 'package:linakan_app/data/repositories/seller_repository.dart';
import 'package:linakan_app/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider authProvider;
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.kKeyAccounts: jsonEncode({
        '08123456789': {
          'userId': 'seller1',
          'userType': UserType.seller.name,
          'password': 'rahasia123',
        },
      }),
    });
    await StorageService.init();
    storage = StorageService.instance;
    authProvider = AuthProvider(
      storage,
      sellerRepo: SellerRepository(storage),
      farmerRepo: FarmerRepository(storage),
    );
  });

  test('login menunggu verifikasi OTP sebelum membuat sesi', () {
    final result = authProvider.loginWithEmailOrPhone(
      '08123456789',
      'rahasia123',
    );

    expect(result.success, isTrue);
    expect(authProvider.isAwaitingOtp, isTrue);
    expect(authProvider.isLoggedIn, isFalse);
    expect(storage.getString(AppConstants.kKeyCurrentUser), isNull);

    expect(authProvider.completeOtpVerification(), isTrue);
    expect(authProvider.isAwaitingOtp, isFalse);
    expect(authProvider.isLoggedIn, isTrue);
    expect(authProvider.currentUserId, 'seller1');
    expect(authProvider.currentUserType, UserType.seller);
    expect(storage.getString(AppConstants.kKeyCurrentUser), isNotNull);
  });

  test('autentikasi tertunda dapat dibatalkan tanpa membuat sesi', () {
    final result = authProvider.loginWithPhone(
      '08123456789',
      'rahasia123',
    );
    expect(result.success, isTrue);

    authProvider.cancelPendingAuthentication();

    expect(authProvider.isAwaitingOtp, isFalse);
    expect(authProvider.isLoggedIn, isFalse);
    expect(authProvider.completeOtpVerification(), isFalse);
    expect(storage.getString(AppConstants.kKeyCurrentUser), isNull);
  });

  test('password akun aktif dapat diganti dan disimpan', () {
    authProvider.loginWithPhone('08123456789', 'rahasia123');
    authProvider.completeOtpVerification();

    final result = authProvider.changePassword(
      currentPassword: 'rahasia123',
      newPassword: 'rahasia456',
    );

    expect(result.success, isTrue);
    authProvider.logout();
    expect(
      authProvider.loginWithPhone('08123456789', 'rahasia123').success,
      isFalse,
    );
    expect(
      authProvider.loginWithPhone('08123456789', 'rahasia456').success,
      isTrue,
    );
  });

  test('farmer terdaftar masuk langsung ke dashboard tanpa onboarding',
      () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.kKeyAccounts: jsonEncode({
        '08129999999': {
          'userId': 'farmer1',
          'userType': UserType.farmer.name,
          'password': 'rahasia123',
        },
      }),
    });
    await StorageService.init();
    final farmerAuth = AuthProvider(
      StorageService.instance,
      sellerRepo: SellerRepository(StorageService.instance),
      farmerRepo: FarmerRepository(StorageService.instance),
    );

    final result = farmerAuth.loginWithPhone('08129999999', 'rahasia123');
    expect(result.success, isTrue);
    expect(farmerAuth.completeOtpVerification(), isTrue);
    expect(farmerAuth.authenticatedHomeRoute, '/farmer/dashboard');
  });
}
