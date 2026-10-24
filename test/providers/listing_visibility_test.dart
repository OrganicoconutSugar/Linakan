import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linakan_app/core/constants/app_constants.dart';
import 'package:linakan_app/core/services/storage_service.dart';
import 'package:linakan_app/data/models/farmer_model.dart';
import 'package:linakan_app/data/models/listing_model.dart';
import 'package:linakan_app/data/models/listing_status.dart';
import 'package:linakan_app/data/models/waste_category.dart';
import 'package:linakan_app/data/repositories/listing_repository.dart';
import 'package:linakan_app/domain/matching_service.dart';
import 'package:linakan_app/domain/shelf_life_service.dart';
import 'package:linakan_app/providers/listing_provider.dart';
import 'package:linakan_app/providers/matching_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('listing baru seller tersedia di Listings, Marketplace, dan Matches',
      () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.kKeyListings: jsonEncode(<Object>[]),
    });
    await StorageService.init();

    final shelfLifeService = ShelfLifeService();
    final listingProvider = ListingProvider(
      ListingRepository(StorageService.instance),
      shelfLifeService,
    );
    final matchingProvider = MatchingProvider(
      MatchingService(shelfLifeService),
      listingProvider,
    );
    final listing = ListingModel(
      id: 'listing-baru',
      sellerId: 'seller-baru',
      sellerName: 'Seller Baru',
      sellerType: 'umkm',
      wasteName: 'Roti Sisa Produksi',
      category: WasteCategory.rotiKering,
      weight: 10,
      pricePerKg: 5000,
      totalPrice: 50000,
      suggestedPrice: 5000,
      finalPrice: 50000,
      location: 'Jakarta',
      lat: -6.2297,
      lng: 106.8419,
      pickupAddress: 'Jl. Seller Baru',
      createdAt: DateTime.now(),
      status: ListingStatus.available,
      quality: 'Baik',
    );
    final farmer = FarmerModel(
      id: 'farmer-baru',
      name: 'Farmer Baru',
      livestock: const ['ayam'],
      feedRequirements: 'Roti kering',
      capacity: 40,
      email: '',
      phone: '081200000001',
      location: 'Jakarta',
      lat: -6.2300,
      lng: 106.8420,
      verified: true,
      joinDate: '2026-10-24',
      walletBalance: 100000,
      averageRating: 0,
      totalTransactions: 0,
    );

    await listingProvider.addListing(listing);
    await matchingProvider.computeMatches(farmer);

    expect(
      listingProvider.getMyListings('seller-baru').map((item) => item.id),
      contains('listing-baru'),
    );
    expect(
      matchingProvider.marketplaceListings.map((item) => item.listing.id),
      contains('listing-baru'),
    );
    expect(
      matchingProvider.allMatches.map((item) => item.listing.id),
      contains('listing-baru'),
    );
  });
}
