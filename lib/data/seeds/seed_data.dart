import '../models/farmer_model.dart';
import '../models/listing_model.dart';
import '../models/listing_status.dart';
import '../models/seller_model.dart';
import '../models/waste_category.dart';

/// Data awal (seed) LINAKAN — port dari getDummySellers/getDummyFarmers/getDummyListings di data.js.
class SeedData {
  SeedData._();

  static List<SellerModel> getDummySellers() {
    return [
      const SellerModel(
        id: 'seller1',
        name: 'Bakery Sejahtera',
        type: 'bakery',
        email: 'bakery@linakan.id',
        phone: '+62812345678',
        location: 'Jakarta Selatan',
        lat: -6.2297,
        lng: 106.8419,
        verified: true,
        joinDate: '2024-01-15',
        walletBalance: 500000,
        averageRating: 4.5,
        totalTransactions: 12,
      ),
      const SellerModel(
        id: 'seller2',
        name: 'IRT Roti Lezat',
        type: 'irt',
        email: 'irt@linakan.id',
        phone: '+62812345679',
        location: 'Tangerang',
        lat: -6.1728,
        lng: 106.6326,
        verified: true,
        joinDate: '2024-02-20',
        walletBalance: 250000,
        averageRating: 4.8,
        totalTransactions: 8,
      ),
    ];
  }

  static List<FarmerModel> getDummyFarmers() {
    return [
      const FarmerModel(
        id: 'farmer1',
        name: 'Pak Budi - Peternak Bebek',
        livestock: ['ayam', 'bebek'],
        feedRequirements: 'Tepung, sisa roti',
        capacity: 20,
        email: 'farmer1@linakan.id',
        phone: '+62812345680',
        location: 'Cilandak',
        lat: -6.2784,
        lng: 106.8027,
        verified: true,
        joinDate: '2024-01-10',
        walletBalance: 1000000,
        averageRating: 4.7,
        totalTransactions: 15,
      ),
      const FarmerModel(
        id: 'farmer2',
        name: 'Kebun Sayur Mandiri',
        livestock: ['sapi', 'kambing'],
        feedRequirements: 'Sayuran, limbah makanan',
        capacity: 200,
        email: 'farmer2@linakan.id',
        phone: '+62812345681',
        location: 'Depok',
        lat: -6.403,
        lng: 106.8193,
        verified: true,
        joinDate: '2024-01-20',
        walletBalance: 750000,
        averageRating: 4.6,
        totalTransactions: 10,
      ),
    ];
  }

  static List<ListingModel> getDummyListings() {
    // createdAt 2 hari lalu agar listing1 masih aktif (rotiKering = 336 jam)
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final oneDayAgo = now.subtract(const Duration(days: 1));

    return [
      ListingModel(
        id: 'listing1',
        sellerId: 'seller1',
        sellerName: 'Bakery Sejahtera',
        sellerType: 'bakery',
        wasteName: 'Roti Kering Sisa Produksi',
        category: WasteCategory.rotiKering,
        weight: 12,
        pricePerKg: 5000,
        totalPrice: 60000,
        suggestedPrice: 6000,
        finalPrice: 60000,
        imageUrl: 'https://via.placeholder.com/400x300?text=Roti+Kering',
        location: 'Jakarta Selatan',
        lat: -6.2297,
        lng: 106.8419,
        pickupAddress: 'Jl. Terogong Raya No. 42, Jakarta',
        createdAt: twoDaysAgo,
        status: ListingStatus.available,
        quality: 'Baik',
        notes: 'Roti kering sisa produksi kemarin',
      ),
      ListingModel(
        id: 'listing2',
        sellerId: 'seller2',
        sellerName: 'IRT Roti Lezat',
        sellerType: 'irt',
        wasteName: 'Tepung Afkir',
        category: WasteCategory.tepungAfkir,
        weight: 20,
        pricePerKg: 4000,
        totalPrice: 80000,
        suggestedPrice: 5000,
        finalPrice: 80000,
        imageUrl: 'https://via.placeholder.com/400x300?text=Tepung',
        location: 'Tangerang',
        lat: -6.1728,
        lng: 106.6326,
        pickupAddress: 'Jl. Balaraja No. 15, Tangerang',
        createdAt: oneDayAgo,
        status: ListingStatus.available,
        quality: 'Sangat Baik',
        notes: 'Tepung kualitas tinggi, sisa produksi',
      ),
      ListingModel(
        id: 'listing3',
        sellerId: 'seller2',
        sellerName: 'IRT Roti Lezat',
        sellerType: 'irt',
        wasteName: 'Sayuran Segar Sisa Pasar',
        category: WasteCategory.sayuranMentah,
        weight: 8,
        pricePerKg: 3500,
        totalPrice: 28000,
        suggestedPrice: 4000,
        finalPrice: 28000,
        imageUrl: 'https://via.placeholder.com/400x300?text=Sayuran',
        location: 'Tangerang',
        lat: -6.1728,
        lng: 106.6326,
        pickupAddress: 'Jl. Balaraja No. 15, Tangerang',
        createdAt: now.subtract(const Duration(hours: 6)),
        status: ListingStatus.available,
        quality: 'Baik',
        notes: 'Sayuran segar sisa hari ini',
      ),
    ];
  }
}
