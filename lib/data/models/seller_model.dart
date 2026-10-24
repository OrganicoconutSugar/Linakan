/// Model data penjual/penghasil limbah (Bakery, IRT, UMKM).
class SellerModel {
  final String id;
  final String name;
  final String type; // 'irt' | 'bakery' | 'umkm_food'
  final String email;
  final String phone;
  final String location;
  final double lat;
  final double lng;
  final bool verified;
  final String joinDate;
  final int walletBalance;
  final double averageRating;
  final int totalTransactions;

  const SellerModel({
    required this.id,
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    required this.location,
    required this.lat,
    required this.lng,
    required this.verified,
    required this.joinDate,
    required this.walletBalance,
    required this.averageRating,
    required this.totalTransactions,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      location: json['location'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      verified: json['verified'] as bool,
      joinDate: json['joinDate'] as String,
      walletBalance: (json['walletBalance'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      totalTransactions: (json['totalTransactions'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'email': email,
      'phone': phone,
      'location': location,
      'lat': lat,
      'lng': lng,
      'verified': verified,
      'joinDate': joinDate,
      'walletBalance': walletBalance,
      'averageRating': averageRating,
      'totalTransactions': totalTransactions,
    };
  }

  SellerModel copyWith({
    String? id,
    String? name,
    String? type,
    String? email,
    String? phone,
    String? location,
    double? lat,
    double? lng,
    bool? verified,
    String? joinDate,
    int? walletBalance,
    double? averageRating,
    int? totalTransactions,
  }) {
    return SellerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      verified: verified ?? this.verified,
      joinDate: joinDate ?? this.joinDate,
      walletBalance: walletBalance ?? this.walletBalance,
      averageRating: averageRating ?? this.averageRating,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SellerModel(id: $id, name: $name)';
}
