import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linakan_app/core/constants/app_constants.dart';
import 'package:linakan_app/core/services/storage_service.dart';
import 'package:linakan_app/data/repositories/farmer_repository.dart';
import 'package:linakan_app/data/repositories/listing_repository.dart';
import 'package:linakan_app/data/repositories/seller_repository.dart';
import 'package:linakan_app/data/repositories/transaction_repository.dart';
import 'package:linakan_app/domain/matching_service.dart';
import 'package:linakan_app/domain/pricing_service.dart';
import 'package:linakan_app/domain/shelf_life_service.dart';
import 'package:linakan_app/domain/wallet_service.dart';
import 'package:linakan_app/providers/auth_provider.dart';
import 'package:linakan_app/providers/listing_provider.dart';
import 'package:linakan_app/providers/matching_provider.dart';
import 'package:linakan_app/providers/notification_provider.dart';
import 'package:linakan_app/providers/transaction_provider.dart';
import 'package:linakan_app/providers/wallet_provider.dart';
import 'package:linakan_app/ui/farmer/farmer_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Farmer dashboard menampilkan panel saldo', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.kKeyCurrentUser: jsonEncode({
        'userId': 'farmer1',
        'userType': UserType.farmer.name,
      }),
    });
    await StorageService.init();
    final storage = StorageService.instance;
    final farmerRepository = FarmerRepository(storage);
    final sellerRepository = SellerRepository(storage);
    final listingRepository = ListingRepository(storage);
    final transactionRepository = TransactionRepository(storage);
    final shelfLifeService = ShelfLifeService();
    final listingProvider = ListingProvider(
      listingRepository,
      shelfLifeService,
    );
    await listingProvider.loadAll();
    final walletService = WalletService(
      farmerRepo: farmerRepository,
      sellerRepo: sellerRepository,
      listingRepo: listingRepository,
      transactionRepo: transactionRepository,
      pricingService: PricingService(),
    );
    final authProvider = AuthProvider(
      storage,
      sellerRepo: sellerRepository,
      farmerRepo: farmerRepository,
    );
    final notificationProvider = NotificationProvider.empty();
    final matchingProvider = MatchingProvider(
      MatchingService(shelfLifeService),
      listingProvider,
      notificationProvider: notificationProvider,
    );
    final transactionProvider = TransactionProvider(
      transactionRepository,
      walletService,
      listingProvider,
    );
    final walletProvider = WalletProvider(
      walletService,
      sellerRepository,
      farmerRepository,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ListingProvider>.value(
            value: listingProvider,
          ),
          ChangeNotifierProvider<MatchingProvider>.value(
            value: matchingProvider,
          ),
          ChangeNotifierProvider<TransactionProvider>.value(
            value: transactionProvider,
          ),
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: notificationProvider,
          ),
          Provider<FarmerRepository>.value(value: farmerRepository),
        ],
        child: const MaterialApp(home: FarmerDashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('dashboard-wallet-balance')), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.textContaining('1.000.000'), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);

    final walletRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-wallet-balance')),
    );
    final contentSheetRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-content-sheet')),
    );
    expect(walletRect.bottom, lessThan(contentSheetRect.top));
  });
}
