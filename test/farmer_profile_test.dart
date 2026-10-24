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
import 'package:linakan_app/providers/transaction_provider.dart';
import 'package:linakan_app/ui/farmer/farmer_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Profil farmer memiliki pengaturan akun dan alamat tersimpan',
      (tester) async {
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
    final listingProvider = ListingProvider(
      listingRepository,
      ShelfLifeService(),
    );
    final walletService = WalletService(
      farmerRepo: farmerRepository,
      sellerRepo: sellerRepository,
      listingRepo: listingRepository,
      transactionRepo: transactionRepository,
      pricingService: PricingService(),
    );
    final transactionProvider = TransactionProvider(
      transactionRepository,
      walletService,
      listingProvider,
    );
    final authProvider = AuthProvider(
      storage,
      sellerRepo: sellerRepository,
      farmerRepo: farmerRepository,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TransactionProvider>.value(
            value: transactionProvider,
          ),
          Provider<FarmerRepository>.value(value: farmerRepository),
        ],
        child: const MaterialApp(home: FarmerProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Profil Peternak'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ganti Alamat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ubah Foto Profil'), findsOneWidget);
    expect(find.text('Ganti Password'), findsOneWidget);
    expect(find.text('Ganti Alamat'), findsOneWidget);

    await tester.tap(find.text('Ganti Alamat'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Jl. Peternakan Baru No. 10',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(
      farmerRepository.getById('farmer1')!.location,
      'Jl. Peternakan Baru No. 10',
    );
  });
}
