import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/storage_service.dart';
import 'data/repositories/farmer_repository.dart';
import 'data/repositories/listing_repository.dart';
import 'data/repositories/seller_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'domain/matching_service.dart';
import 'domain/pricing_service.dart';
import 'domain/shelf_life_service.dart';
import 'domain/wallet_service.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/matching_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi StorageService (SharedPreferences)
  await StorageService.init();
  final storage = StorageService.instance;

  // 2. Inisialisasi locale id_ID untuk DateFormat (intl)
  await initializeDateFormatting('id_ID');

  // 2. Seed data jika versi belum cocok
  final dataVersion = storage.getString(AppConstants.kKeyDataVersion);
  if (dataVersion != AppConstants.kSeedDataVersion) {
    await storage.clear();
    await storage.setString(
      AppConstants.kKeyDataVersion,
      AppConstants.kSeedDataVersion,
    );
  }

  await _seedAdminAccount(storage);

  // 3. Buat repositories
  final sellerRepo = SellerRepository(storage);
  final farmerRepo = FarmerRepository(storage);
  final listingRepo = ListingRepository(storage);
  final transactionRepo = TransactionRepository(storage);

  // 4. Buat domain services
  final shelfLifeService = ShelfLifeService();
  final pricingService = PricingService();
  final matchingService = MatchingService(shelfLifeService);
  final walletService = WalletService(
    farmerRepo: farmerRepo,
    sellerRepo: sellerRepo,
    listingRepo: listingRepo,
    transactionRepo: transactionRepo,
    pricingService: pricingService,
  );

  // 5. Buat providers
  final authProvider = AuthProvider(
    storage,
    sellerRepo: sellerRepo,
    farmerRepo: farmerRepo,
  );
  final notificationProvider = NotificationProvider(storage, authProvider);
  final listingProvider = ListingProvider(listingRepo, shelfLifeService);
  await listingProvider.loadAll();

  final matchingProvider = MatchingProvider(
    matchingService,
    listingProvider,
    notificationProvider: notificationProvider,
  );
  final transactionProvider = TransactionProvider(
    transactionRepo,
    walletService,
    listingProvider,
    notificationProvider: notificationProvider,
  );
  await transactionProvider.loadTransactions();

  final walletProvider = WalletProvider(
    walletService,
    sellerRepo,
    farmerRepo,
  );

  // 6. Jalankan app dengan MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
            value: notificationProvider),
        ChangeNotifierProvider<ListingProvider>.value(value: listingProvider),
        ChangeNotifierProvider<MatchingProvider>.value(value: matchingProvider),
        ChangeNotifierProvider<TransactionProvider>.value(
            value: transactionProvider),
        ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
        // Repositories exposed for screens that need fresh model data
        Provider<FarmerRepository>.value(value: farmerRepo),
        Provider<SellerRepository>.value(value: sellerRepo),
      ],
      // AuthProvider dikelola di LinakanApp agar GoRouter bisa listen ke perubahan login
      child: LinakanApp(authProvider: authProvider),
    ),
  );
}

Future<void> _seedAdminAccount(StorageService storage) async {
  final raw = storage.getString(AppConstants.kKeyAccounts);
  final accounts = <String, dynamic>{};
  if (raw != null) {
    try {
      accounts.addAll(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      // Pulihkan storage akun yang tidak valid dengan seed admin yang aman.
    }
  }

  if (!accounts.containsKey(AppConstants.kAdminPhone)) {
    accounts[AppConstants.kAdminPhone] = {
      'userId': AppConstants.kAdminUserId,
      'userType': 'admin',
      'password': AppConstants.kAdminPassword,
    };
  }
  if (!accounts.containsKey(AppConstants.kAdminEmail)) {
    accounts[AppConstants.kAdminEmail] = {
      'userId': AppConstants.kAdminUserId,
      'userType': 'admin',
      'password': AppConstants.kAdminPassword,
    };
  }

  await storage.setString(AppConstants.kKeyAccounts, jsonEncode(accounts));
}
