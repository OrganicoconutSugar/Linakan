import 'listing_status.dart';
import 'waste_category.dart';

/// Model listing limbah pangan yang didaftarkan penjual.
class ListingModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerType;
  final String wasteName;
  final WasteCategory category;
  final String? customCategory;
  final double weight; // kg
  final int pricePerKg;
  final int totalPrice;
  final int suggestedPrice;
  final int finalPrice;
  final String? imageUrl;
  final String location;
  final double lat;
  final double lng;
  final String pickupAddress;
  final DateTime createdAt;
  final ListingStatus status;
  final String quality;
  final String? notes;

  const ListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerType,
    required this.wasteName,
    required this.category,
    this.customCategory,
    required this.weight,
    required this.pricePerKg,
    required this.totalPrice,
    required this.suggestedPrice,
    required this.finalPrice,
    this.imageUrl,
    required this.location,
    required this.lat,
    required this.lng,
    required this.pickupAddress,
    required this.createdAt,
    required this.status,
    required this.quality,
    this.notes,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      sellerType: json['sellerType'] as String,
      wasteName: json['wasteName'] as String,
      category: WasteCategoryExtension.fromId(json['category'] as String),
      customCategory: json['customCategory'] as String?,
      weight: (json['weight'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toInt(),
      suggestedPrice: (json['suggestedPrice'] as num).toInt(),
      finalPrice: (json['finalPrice'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      pickupAddress: json['pickupAddress'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ListingStatusExtension.fromId(json['status'] as String),
      quality: json['quality'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerType': sellerType,
      'wasteName': wasteName,
      'category': category.id,
      'customCategory': customCategory,
      'weight': weight,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'suggestedPrice': suggestedPrice,
      'finalPrice': finalPrice,
      'imageUrl': imageUrl,
      'location': location,
      'lat': lat,
      'lng': lng,
      'pickupAddress': pickupAddress,
      'createdAt': createdAt.toIso8601String(),
      'status': status.id,
      'quality': quality,
      'notes': notes,
    };
  }

  ListingModel copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerType,
    String? wasteName,
    WasteCategory? category,
    String? customCategory,
    double? weight,
    int? pricePerKg,
    int? totalPrice,
    int? suggestedPrice,
    int? finalPrice,
    String? imageUrl,
    String? location,
    double? lat,
    double? lng,
    String? pickupAddress,
    DateTime? createdAt,
    ListingStatus? status,
    String? quality,
    String? notes,
  }) {
    return ListingModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerType: sellerType ?? this.sellerType,
      wasteName: wasteName ?? this.wasteName,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      weight: weight ?? this.weight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ListingModel(id: $id, wasteName: $wasteName)';
}
