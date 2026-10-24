import 'package:flutter/foundation.dart';

import '../data/models/farmer_model.dart';
import '../data/models/listing_model.dart';
import '../data/models/listing_status.dart';
import '../data/models/seller_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/wallet_service.dart';
import 'listing_provider.dart';
import 'notification_provider.dart';

/// Provider untuk transaksi LINAKAN.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final WalletService _walletService;
  final ListingProvider _listingProvider;
  final NotificationProvider? _notificationProvider;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  TransactionProvider(
    this._transactionRepository,
    this._walletService,
    this._listingProvider, {
    NotificationProvider? notificationProvider,
  }) : _notificationProvider = notificationProvider;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _transactions = _transactionRepository.getAll();
    } catch (e) {
      _error = 'Gagal memuat data transaksi. Silakan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Transaksi milik user tertentu (sebagai peternak atau penjual).
  List<TransactionModel> getMyTransactions(String userId) {
    return _transactions
        .where((t) => t.farmerId == userId || t.sellerId == userId)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Konfirmasi Transaksi
  // ---------------------------------------------------------------------------

  /// Konfirmasi transaksi:
  /// 1. Panggil WalletService.processTransaction → kurangi saldo peternak, tambah penjual.
  /// 2. Update status listing ke reserved.
  /// 3. Reload daftar transaksi.
  ///
  /// Ini adalah SATU-SATUNYA tempat transisi listing → reserved terjadi.
  Future<TransactionResult> confirmTransaction({
    required ListingModel listing,
    required FarmerModel farmer,
    required SellerModel seller,
  }) async {
    final result = _walletService.processTransaction(
      farmerId: farmer.id,
      sellerId: seller.id,
      listingId: listing.id,
    );

    if (result.success) {
      _notificationProvider?.add(
        title: 'Transaksi Dikonfirmasi',
        message:
            'Pesanan ${seller.name} untuk ${farmer.name} berhasil dikonfirmasi.',
        type: 'transaction',
      );
      // WalletService sudah mengubah status listing di repository.
      // Sync ListingProvider agar UI diperbarui.
      await _listingProvider.updateStatus(listing.id, ListingStatus.reserved);
      await loadTransactions();
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Selesaikan Transaksi
  // ---------------------------------------------------------------------------

  /// Tandai transaksi selesai (status → 'completed') dan update listing
  /// terkait ke [ListingStatus.completed]. Dipanggil peternak dari layar
  /// transaksi melalui tombol 'Selesaikan Transaksi'.
  Future<void> completeTransaction(String transactionId) async {
    final txn = _transactions.where((t) => t.id == transactionId).firstOrNull;
    if (txn == null) return;
    _transactionRepository.update(txn.copyWith(status: 'completed'));
    _notificationProvider?.add(
      title: 'Transaksi Selesai',
      message: 'Transaksi ${txn.listingId} telah diselesaikan.',
      type: 'transaction',
    );
    await _listingProvider.updateStatus(
      txn.listingId,
      ListingStatus.completed,
    );
    await loadTransactions();
  }
}
