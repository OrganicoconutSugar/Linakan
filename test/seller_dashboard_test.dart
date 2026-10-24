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
import 'package:linakan_app/domain/pricing_service.dart';
import 'package:linakan_app/domain/shelf_life_service.dart';
import 'package:linakan_app/domain/wallet_service.dart';
import 'package:linakan_app/providers/auth_provider.dart';
import 'package:linakan_app/providers/listing_provider.dart';
import 'package:linakan_app/providers/notification_provider.dart';
import 'package:linakan_app/providers/transaction_provider.dart';
import 'package:linakan_app/providers/wallet_provider.dart';
import 'package:linakan_app/ui/seller/seller_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider authProvider;
  late ListingProvider listingProvider;
  late TransactionProvider transactionProvider;
  late WalletProvider walletProvider;
  late SellerRepository sellerRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.kKeyCurrentUser: jsonEncode({
        'userId': 'seller1',
        'userType': UserType.seller.name,
      }),
    });
    await StorageService.init();
    final storage = StorageService.instance;

    sellerRepository = SellerRepository(storage);
    final farmerRepository = FarmerRepository(storage);
    final listingRepository = ListingRepository(storage);
    final transactionRepository = TransactionRepository(storage);
    final shelfLifeService = ShelfLifeService();

    authProvider = AuthProvider(
      storage,
      sellerRepo: sellerRepository,
      farmerRepo: farmerRepository,
    );
    listingProvider = ListingProvider(listingRepository, shelfLifeService);
    await listingProvider.loadAll();

    final walletService = WalletService(
      farmerRepo: farmerRepository,
      sellerRepo: sellerRepository,
      listingRepo: listingRepository,
      transactionRepo: transactionRepository,
      pricingService: PricingService(),
    );
    transactionProvider = TransactionProvider(
      transactionRepository,
      walletService,
      listingProvider,
    );
    await transactionProvider.loadTransactions();
    walletProvider = WalletProvider(
      walletService,
      sellerRepository,
      farmerRepository,
    );
  });

  testWidgets('Seller dashboard shows saldo', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ListingProvider>.value(
            value: listingProvider,
          ),
          ChangeNotifierProvider<TransactionProvider>.value(
            value: transactionProvider,
          ),
          ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: NotificationProvider.empty(),
          ),
          Provider<SellerRepository>.value(value: sellerRepository),
        ],
        child: const MaterialApp(home: SellerDashboardScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Saldo'), findsOneWidget);
    expect(find.textContaining('500.000'), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);

    final walletRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-wallet-balance')),
    );
    final contentSheetRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-content-sheet')),
    );
    expect(walletRect.bottom, lessThan(contentSheetRect.top));

    await tester.tap(find.byKey(const ValueKey('wallet-header-top-up')));
    await tester.pumpAndSettle();

    expect(find.text('Top Up Dompet'), findsOneWidget);
    expect(find.text('Konfirmasi Top Up'), findsOneWidget);

    await tester.tap(find.text('Rp 50.000'));
    await tester.pump();
    await tester.tap(find.text('Konfirmasi Top Up'));
    await tester.pumpAndSettle();

    expect(find.textContaining('550.000'), findsOneWidget);
  });
}
