import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../models/seller_model.dart';
import '../seeds/seed_data.dart';

/// Repository untuk data penjual. Load dari StorageService,
/// seed dari SeedData jika belum ada, dan langsung persist tiap mutasi.
class SellerRepository {
  final StorageService _storage;

  SellerRepository(this._storage);

  // --- Load ---

  List<SellerModel> getAll() {
    final raw = _storage.getString(AppConstants.kKeySellers);
    if (raw == null) {
      final seeds = SeedData.getDummySellers();
      _persist(seeds);
      return seeds;
    }
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SellerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  SellerModel? getById(String id) {
    return getAll().where((s) => s.id == id).firstOrNull;
  }

  // --- Mutasi ---

  void add(SellerModel seller) {
    final list = getAll()..add(seller);
    _persist(list);
  }

  void update(SellerModel seller) {
    final list = getAll().map((s) => s.id == seller.id ? seller : s).toList();
    _persist(list);
  }

  void delete(String id) {
    final list = getAll().where((s) => s.id != id).toList();
    _persist(list);
  }

  // --- Private ---

  void _persist(List<SellerModel> list) {
    _storage.setString(
      AppConstants.kKeySellers,
      jsonEncode(list.map((s) => s.toJson()).toList()),
    );
  }
}
