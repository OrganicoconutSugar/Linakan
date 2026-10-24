import '../data/models/farmer_model.dart';
import '../data/models/listing_status.dart';
import '../data/models/seller_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/waste_category.dart';
import '../data/repositories/farmer_repository.dart';
import '../data/repositories/listing_repository.dart';
import '../data/repositories/seller_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'pricing_service.dart';

/// Hasil ringkasan dompet.
class WalletSummary {
  final String userId;
  final String name;
  final int balance;
  final int totalAmount; // total earnings (seller) atau total spent (farmer)
  final int totalTransactions;

  const WalletSummary({
    required this.userId,
    required this.name,
    required this.balance,
    required this.totalAmount,
    required this.totalTransactions,
  });
}

/// Hasil top-up dompet.
class TopUpResult {
  final bool success;
  final String? error;
  final int? newBalance;

  const TopUpResult({required this.success, this.error, this.newBalance});
}

/// Hasil transaksi.
class TransactionResult {
  final bool success;
  final String? error;
  final TransactionModel? transaction;
  final int? farmerBalance;
  final int? sellerBalance;

  const TransactionResult({
    required this.success,
    this.error,
    this.transaction,
    this.farmerBalance,
    this.sellerBalance,
  });
}

/// Hasil permintaan penarikan.
class WithdrawalResult {
  final bool success;
  final String? error;
  final int? currentBalance;

  const WithdrawalResult({
    required this.success,
    this.error,
    this.currentBalance,
  });
}

/// Layanan dompet elektronik LINAKAN.
/// Pure Dart — tidak ada import Flutter.
class WalletService {
  final FarmerRepository _farmerRepo;
  final SellerRepository _sellerRepo;
  final ListingRepository _listingRepo;
  final TransactionRepository _transactionRepo;
  final PricingService _pricingService;

  WalletService({
    required FarmerRepository farmerRepo,
    required SellerRepository sellerRepo,
    required ListingRepository listingRepo,
    required TransactionRepository transactionRepo,
    required PricingService pricingService,
  })  : _farmerRepo = farmerRepo,
        _sellerRepo = sellerRepo,
        _listingRepo = listingRepo,
        _transactionRepo = transactionRepo,
        _pricingService = pricingService;

  /// Proses transaksi: kurangi saldo peternak, tambah saldo penjual, simpan transaksi.
  TransactionResult processTransaction({
    required String farmerId,
    required String sellerId,
    required String listingId,
  }) {
    final farmer = _farmerRepo.getById(farmerId);
    final seller = _sellerRepo.getById(sellerId);
    final listing = _listingRepo.getById(listingId);

    if (farmer == null || seller == null) {
      return const TransactionResult(
          success: false, error: 'Peternak atau penjual tidak ditemukan');
    }
    if (listing == null) {
      return const TransactionResult(
          success: false, error: 'Listing tidak ditemukan');
    }
    if (listing.sellerId != sellerId) {
      return const TransactionResult(
        success: false,
        error: 'Data penjual tidak sesuai dengan listing',
      );
    }
    if (listing.status != ListingStatus.available) {
      return const TransactionResult(
        success: false,
        error: 'Listing sudah tidak tersedia',
      );
    }
    if (listing.finalPrice <= 0) {
      return const TransactionResult(
        success: false,
        error: 'Harga listing tidak valid',
      );
    }

    final sellerEarns =
        _pricingService.calculateSellerEarnings(listing.finalPrice);
    final farmerPays =
        _pricingService.calculateFarmerCheckout(listing.finalPrice);
    final platformFee = listing.finalPrice - sellerEarns;

    if (farmer.walletBalance < farmerPays) {
      return const TransactionResult(
        success: false,
        error: 'Saldo dompet tidak mencukupi',
      );
    }

    // Update saldo
    final newFarmerBalance = farmer.walletBalance - farmerPays;
    final newSellerBalance = seller.walletBalance + sellerEarns;
    _farmerRepo.update(farmer.copyWith(walletBalance: newFarmerBalance));
    _sellerRepo.update(seller.copyWith(walletBalance: newSellerBalance));

    // Update status listing
    _listingRepo.update(listing.copyWith(status: ListingStatus.reserved));

    // Simpan transaksi
    final txn = TransactionModel(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: farmerId,
      sellerId: sellerId,
      listingId: listingId,
      wasteName: listing.wasteName,
      wasteCategory: listing.category.id,
      listingWeight: listing.weight,
      totalPrice: listing.finalPrice,
      platformFee: platformFee,
      sellerReceives: sellerEarns,
      farmerPays: farmerPays,
      status: 'confirmed',
      createdAt: DateTime.now(),
    );
    _transactionRepo.add(txn);

    return TransactionResult(
      success: true,
      transaction: txn,
      farmerBalance: newFarmerBalance,
      sellerBalance: newSellerBalance,
    );
  }

  /// Top-up saldo dompet (peternak atau penjual).
  TopUpResult topUp(String userId, int amount, String method) {
    if (amount <= 0) {
      return const TopUpResult(
        success: false,
        error: 'Nominal top up harus lebih dari nol',
      );
    }

    // Coba peternak dulu
    FarmerModel? farmer = _farmerRepo.getById(userId);
    if (farmer != null) {
      final newBalance = farmer.walletBalance + amount;
      _farmerRepo.update(farmer.copyWith(walletBalance: newBalance));
      return TopUpResult(success: true, newBalance: newBalance);
    }

    // Coba penjual
    SellerModel? seller = _sellerRepo.getById(userId);
    if (seller != null) {
      final newBalance = seller.walletBalance + amount;
      _sellerRepo.update(seller.copyWith(walletBalance: newBalance));
      return TopUpResult(success: true, newBalance: newBalance);
    }

    return const TopUpResult(success: false, error: 'Pengguna tidak ditemukan');
  }

  /// Ringkasan dompet untuk penjual.
  WalletSummary? getSellerSummary(String sellerId) {
    final seller = _sellerRepo.getById(sellerId);
    if (seller == null) return null;

    final txns = _transactionRepo
        .getAll()
        .where(
          (t) =>
              t.sellerId == sellerId &&
              (t.status == 'confirmed' || t.status == 'completed'),
        )
        .toList();

    final totalEarnings = txns.fold<int>(0, (sum, t) => sum + t.sellerReceives);

    return WalletSummary(
      userId: sellerId,
      name: seller.name,
      balance: seller.walletBalance,
      totalAmount: totalEarnings,
      totalTransactions: txns.length,
    );
  }

  /// Ringkasan dompet untuk peternak.
  WalletSummary? getFarmerSummary(String farmerId) {
    final farmer = _farmerRepo.getById(farmerId);
    if (farmer == null) return null;

    final txns = _transactionRepo
        .getAll()
        .where(
          (t) =>
              t.farmerId == farmerId &&
              (t.status == 'confirmed' || t.status == 'completed'),
        )
        .toList();

    final totalSpent = txns.fold<int>(0, (sum, t) => sum + t.farmerPays);

    return WalletSummary(
      userId: farmerId,
      name: farmer.name,
      balance: farmer.walletBalance,
      totalAmount: totalSpent,
      totalTransactions: txns.length,
    );
  }

  /// Permintaan penarikan saldo untuk penjual.
  WithdrawalResult requestWithdrawal(
    String sellerId,
    int amount,
    String bankAccount,
  ) {
    final seller = _sellerRepo.getById(sellerId);
    if (seller == null) {
      return const WithdrawalResult(
          success: false, error: 'Penjual tidak ditemukan');
    }
    if (amount <= 0) {
      return WithdrawalResult(
        success: false,
        error: 'Nominal penarikan harus lebih dari nol',
        currentBalance: seller.walletBalance,
      );
    }
    if (seller.walletBalance < amount) {
      return WithdrawalResult(
        success: false,
        error: 'Saldo tidak mencukupi',
        currentBalance: seller.walletBalance,
      );
    }
    // Dalam sistem nyata, saldo baru dikurangi setelah penarikan dikonfirmasi.
    return WithdrawalResult(
      success: true,
      currentBalance: seller.walletBalance,
    );
  }
}
