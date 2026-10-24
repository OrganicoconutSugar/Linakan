import 'package:flutter/foundation.dart';

import '../core/utils/currency_formatter.dart';
import '../data/repositories/farmer_repository.dart';
import '../data/repositories/seller_repository.dart';
import '../domain/wallet_service.dart';

/// Provider untuk dompet elektronik LINAKAN.
class WalletProvider extends ChangeNotifier {
  final WalletService _walletService;
  final SellerRepository _sellerRepository;
  final FarmerRepository _farmerRepository;

  int _balance = 0;
  bool _loading = false;
  String? _error;

  WalletProvider(
    this._walletService,
    this._sellerRepository,
    this._farmerRepository,
  );

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  int get balance => _balance;
  bool get loading => _loading;
  String? get error => _error;

  /// Saldo diformat sebagai Rupiah (mis. 'Rp 500.000').
  String get formattedBalance => formatRupiah(_balance);

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadBalance(String userId, String userType) async {
    _loading = true;
    _error = null;
    notifyListeners();

    if (userType == 'seller') {
      final summary = _walletService.getSellerSummary(userId);
      _balance = summary?.balance ??
          _sellerRepository.getById(userId)?.walletBalance ??
          0;
    } else if (userType == 'farmer') {
      final summary = _walletService.getFarmerSummary(userId);
      _balance = summary?.balance ??
          _farmerRepository.getById(userId)?.walletBalance ??
          0;
    } else {
      _balance = 0;
    }

    _loading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Top Up
  // ---------------------------------------------------------------------------

  Future<void> topUp(String userId, int amount, String method) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = _walletService.topUp(userId, amount, method);
    if (result.success) {
      _balance = result.newBalance ?? _balance;
    } else {
      _error = result.error;
    }

    _loading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Withdrawal
  // ---------------------------------------------------------------------------

  Future<void> requestWithdrawal(String sellerId, int amount) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = _walletService.requestWithdrawal(
      sellerId,
      amount,
      'bank_transfer',
    );
    if (!result.success) {
      _error = result.error;
    }

    _loading = false;
    notifyListeners();
  }
}
