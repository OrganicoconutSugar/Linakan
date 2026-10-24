/// Model transaksi antara peternak dan penjual.
class TransactionModel {
  final String id;
  final String farmerId;
  final String sellerId;
  final String listingId;
  final String wasteName;
  final String wasteCategory;
  final double listingWeight;
  final int totalPrice;
  final int platformFee;
  final int sellerReceives;
  final int farmerPays;
  final String status; // 'pending' | 'confirmed' | 'completed' | 'cancelled'
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.farmerId,
    required this.sellerId,
    required this.listingId,
    required this.wasteName,
    required this.wasteCategory,
    required this.listingWeight,
    required this.totalPrice,
    required this.platformFee,
    required this.sellerReceives,
    required this.farmerPays,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      farmerId: json['farmerId'] as String,
      sellerId: json['sellerId'] as String,
      listingId: json['listingId'] as String,
      wasteName: json['wasteName'] as String? ?? '',
      wasteCategory: json['wasteCategory'] as String? ?? '',
      listingWeight: (json['listingWeight'] as num? ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] as num? ?? 0).toInt(),
      platformFee: (json['platformFee'] as num? ?? 0).toInt(),
      sellerReceives: (json['sellerReceives'] as num? ?? 0).toInt(),
      farmerPays: (json['farmerPays'] as num? ?? 0).toInt(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'wasteName': wasteName,
      'wasteCategory': wasteCategory,
      'listingWeight': listingWeight,
      'totalPrice': totalPrice,
      'platformFee': platformFee,
      'sellerReceives': sellerReceives,
      'farmerPays': farmerPays,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? farmerId,
    String? sellerId,
    String? listingId,
    String? wasteName,
    String? wasteCategory,
    double? listingWeight,
    int? totalPrice,
    int? platformFee,
    int? sellerReceives,
    int? farmerPays,
    String? status,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      sellerId: sellerId ?? this.sellerId,
      listingId: listingId ?? this.listingId,
      wasteName: wasteName ?? this.wasteName,
      wasteCategory: wasteCategory ?? this.wasteCategory,
      listingWeight: listingWeight ?? this.listingWeight,
      totalPrice: totalPrice ?? this.totalPrice,
      platformFee: platformFee ?? this.platformFee,
      sellerReceives: sellerReceives ?? this.sellerReceives,
      farmerPays: farmerPays ?? this.farmerPays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TransactionModel(id: $id, farmerId: $farmerId, sellerId: $sellerId)';
}
