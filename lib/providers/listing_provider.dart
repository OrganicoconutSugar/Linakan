import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/models/listing_model.dart';
import '../data/models/listing_status.dart';
import '../data/repositories/listing_repository.dart';
import '../domain/shelf_life_service.dart';

/// Provider untuk manajemen listing limbah pangan.
class ListingProvider extends ChangeNotifier {
  final ListingRepository _repository;
  final ShelfLifeService _shelfLifeService;

  List<ListingModel> _listings = [];
  bool _isLoading = false;
  String? _error;

  ListingProvider(this._repository, this._shelfLifeService);

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<ListingModel> get listings => List.unmodifiable(_listings);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Listings yang belum kadaluarsa berdasarkan ShelfLifeService.
  List<ListingModel> get activeListings => _listings
      .where((l) => !_shelfLifeService.isExpired(l.category, l.createdAt))
      .toList();

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _listings = _repository.getAll();
    } catch (e) {
      _error = 'Gagal memuat data listing. Silakan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listings milik seller tertentu.
  List<ListingModel> getMyListings(String sellerId) {
    return _listings.where((l) => l.sellerId == sellerId).toList();
  }

  // ---------------------------------------------------------------------------
  // Mutasi
  // ---------------------------------------------------------------------------

  /// Tambah listing baru.
  /// Melempar [ArgumentError] jika berat < [AppConstants.kMinListingWeight].
  Future<void> addListing(ListingModel listing) async {
    if (listing.weight < AppConstants.kMinListingWeight) {
      throw ArgumentError(
        'Berat minimum listing adalah ${AppConstants.kMinListingWeight} kg. '
        'Masukkan berat minimal ${AppConstants.kMinListingWeight} kg.',
      );
    }
    _repository.add(listing);
    await loadAll();
  }

  /// Perbarui status listing berdasarkan id.
  Future<void> updateStatus(String id, ListingStatus status) async {
    final listing = _repository.getById(id);
    if (listing == null) return;
    _repository.update(listing.copyWith(status: status));
    await loadAll();
  }

  /// Hapus listing berdasarkan id.
  Future<void> deleteListing(String id) async {
    _repository.delete(id);
    await loadAll();
  }
}
