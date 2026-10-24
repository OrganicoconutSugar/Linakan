import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../models/listing_model.dart';
import '../seeds/seed_data.dart';

/// Repository untuk data listing limbah.
class ListingRepository {
  final StorageService _storage;

  ListingRepository(this._storage);

  List<ListingModel> getAll() {
    final raw = _storage.getString(AppConstants.kKeyListings);
    if (raw == null) {
      final seeds = SeedData.getDummyListings();
      _persist(seeds);
      return seeds;
    }
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  ListingModel? getById(String id) {
    return getAll().where((l) => l.id == id).firstOrNull;
  }

  void add(ListingModel listing) {
    final list = getAll()..add(listing);
    _persist(list);
  }

  void update(ListingModel listing) {
    final list = getAll().map((l) => l.id == listing.id ? listing : l).toList();
    _persist(list);
  }

  void delete(String id) {
    final list = getAll().where((l) => l.id != id).toList();
    _persist(list);
  }

  void _persist(List<ListingModel> list) {
    _storage.setString(
      AppConstants.kKeyListings,
      jsonEncode(list.map((l) => l.toJson()).toList()),
    );
  }
}
