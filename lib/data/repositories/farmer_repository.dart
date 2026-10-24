import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../models/farmer_model.dart';
import '../seeds/seed_data.dart';

/// Repository untuk data peternak.
class FarmerRepository {
  final StorageService _storage;

  FarmerRepository(this._storage);

  List<FarmerModel> getAll() {
    final raw = _storage.getString(AppConstants.kKeyFarmers);
    if (raw == null) {
      final seeds = SeedData.getDummyFarmers();
      _persist(seeds);
      return seeds;
    }
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FarmerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  FarmerModel? getById(String id) {
    return getAll().where((f) => f.id == id).firstOrNull;
  }

  void add(FarmerModel farmer) {
    final list = getAll()..add(farmer);
    _persist(list);
  }

  void update(FarmerModel farmer) {
    final list = getAll().map((f) => f.id == farmer.id ? farmer : f).toList();
    _persist(list);
  }

  void delete(String id) {
    final list = getAll().where((f) => f.id != id).toList();
    _persist(list);
  }

  void _persist(List<FarmerModel> list) {
    _storage.setString(
      AppConstants.kKeyFarmers,
      jsonEncode(list.map((f) => f.toJson()).toList()),
    );
  }
}
