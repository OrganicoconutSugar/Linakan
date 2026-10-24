import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linakan_app/core/services/storage_service.dart';
import 'package:linakan_app/data/models/listing_status.dart';
import 'package:linakan_app/data/repositories/farmer_repository.dart';
import 'package:linakan_app/data/repositories/listing_repository.dart';
import 'package:linakan_app/data/repositories/seller_repository.dart';
import 'package:linakan_app/data/repositories/transaction_repository.dart';
import 'package:linakan_app/domain/pricing_service.dart';
import 'package:linakan_app/domain/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FarmerRepository farmerRepository;
  late ListingRepository listingRepository;
  late SellerRepository sellerRepository;
  late TransactionRepository transactionRepository;
  late WalletService walletService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final storage = StorageService.instance;

    farmerRepository = FarmerRepository(storage);
    listingRepository = ListingRepository(storage);
    sellerRepository = SellerRepository(storage);
    transactionRepository = TransactionRepository(storage);
    walletService = WalletService(
      farmerRepo: farmerRepository,
      sellerRepo: sellerRepository,
      listingRepo: listingRepository,
      transactionRepo: transactionRepository,
      pricingService: PricingService(),
    );
  });

  test('listing yang sama tidak dapat ditransaksikan dua kali', () {
    final first = walletService.processTransaction(
      farmerId: 'farmer1',
      sellerId: 'seller1',
      listingId: 'listing1',
    );
    final balanceAfterFirst =
        farmerRepository.getById('farmer1')!.walletBalance;

    final second = walletService.processTransaction(
      farmerId: 'farmer1',
      sellerId: 'seller1',
      listingId: 'listing1',
    );

    expect(first.success, isTrue);
    expect(second.success, isFalse);
    expect(second.error, contains('tidak tersedia'));
    expect(
      farmerRepository.getById('farmer1')!.walletBalance,
      balanceAfterFirst,
    );
    expect(transactionRepository.getAll(), hasLength(1));
    expect(
      listingRepository.getById('listing1')!.status,
      ListingStatus.reserved,
    );
  });

  test('top up menolak nominal nol atau negatif', () {
    final startingBalance = farmerRepository.getById('farmer1')!.walletBalance;

    final zeroResult = walletService.topUp('farmer1', 0, 'bank_transfer');
    final negativeResult =
        walletService.topUp('farmer1', -50000, 'bank_transfer');

    expect(zeroResult.success, isFalse);
    expect(negativeResult.success, isFalse);
    expect(
      farmerRepository.getById('farmer1')!.walletBalance,
      startingBalance,
    );
  });

  test('top up menambah saldo farmer dan seller', () {
    final farmerBefore = farmerRepository.getById('farmer1')!.walletBalance;
    final sellerBefore = sellerRepository.getById('seller1')!.walletBalance;

    final farmerResult =
        walletService.topUp('farmer1', 50000, 'BCA Transfer');
    final sellerResult =
        walletService.topUp('seller1', 100000, 'Mandiri Transfer');

    expect(farmerResult.success, isTrue);
    expect(sellerResult.success, isTrue);
    expect(
      farmerRepository.getById('farmer1')!.walletBalance,
      farmerBefore + 50000,
    );
    expect(
      sellerRepository.getById('seller1')!.walletBalance,
      sellerBefore + 100000,
    );
  });

  test('transaksi menolak penjual yang tidak sesuai listing', () {
    final result = walletService.processTransaction(
      farmerId: 'farmer1',
      sellerId: 'seller2',
      listingId: 'listing1',
    );

    expect(result.success, isFalse);
    expect(result.error, contains('tidak sesuai'));
    expect(transactionRepository.getAll(), isEmpty);
  });
}
