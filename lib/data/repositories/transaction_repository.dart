import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../models/transaction_model.dart';

/// Repository untuk data transaksi.
class TransactionRepository {
  final StorageService _storage;

  TransactionRepository(this._storage);

  List<TransactionModel> getAll() {
    final raw = _storage.getString(AppConstants.kKeyTransactions);
    if (raw == null) {
      return [];
    }
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  TransactionModel? getById(String id) {
    return getAll().where((t) => t.id == id).firstOrNull;
  }

  void add(TransactionModel transaction) {
    final list = getAll()..add(transaction);
    _persist(list);
  }

  void update(TransactionModel transaction) {
    final list =
        getAll().map((t) => t.id == transaction.id ? transaction : t).toList();
    _persist(list);
  }

  void delete(String id) {
    final list = getAll().where((t) => t.id != id).toList();
    _persist(list);
  }

  void _persist(List<TransactionModel> list) {
    _storage.setString(
      AppConstants.kKeyTransactions,
      jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }
}
