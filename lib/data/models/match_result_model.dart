import 'listing_model.dart';

/// Hasil pencocokan antara satu listing dengan satu peternak.
class MatchResultModel {
  final ListingModel listing;
  final int score; // 0–100
  final bool isInstantMatch;
  final bool expired;
  final int categoryScore;
  final int locationScore;
  final int capacityScore;
  final double distance; // km
  final List<String> categoryReasons;
  final int capacityPercentage;

  const MatchResultModel({
    required this.listing,
    required this.score,
    required this.isInstantMatch,
    this.expired = false,
    required this.categoryScore,
    required this.locationScore,
    required this.capacityScore,
    required this.distance,
    this.categoryReasons = const [],
    required this.capacityPercentage,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      listing: ListingModel.fromJson(json['listing'] as Map<String, dynamic>),
      score: (json['score'] as num).toInt(),
      isInstantMatch: json['isInstantMatch'] as bool,
      expired: json['expired'] as bool? ?? false,
      categoryScore: (json['categoryScore'] as num).toInt(),
      locationScore: (json['locationScore'] as num).toInt(),
      capacityScore: (json['capacityScore'] as num).toInt(),
      distance: (json['distance'] as num).toDouble(),
      categoryReasons: List<String>.from(
        json['categoryReasons'] as List? ?? [],
      ),
      capacityPercentage: (json['capacityPercentage'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing': listing.toJson(),
      'score': score,
      'isInstantMatch': isInstantMatch,
      'expired': expired,
      'categoryScore': categoryScore,
      'locationScore': locationScore,
      'capacityScore': capacityScore,
      'distance': distance,
      'categoryReasons': categoryReasons,
      'capacityPercentage': capacityPercentage,
    };
  }

  MatchResultModel copyWith({
    ListingModel? listing,
    int? score,
    bool? isInstantMatch,
    bool? expired,
    int? categoryScore,
    int? locationScore,
    int? capacityScore,
    double? distance,
    List<String>? categoryReasons,
    int? capacityPercentage,
  }) {
    return MatchResultModel(
      listing: listing ?? this.listing,
      score: score ?? this.score,
      isInstantMatch: isInstantMatch ?? this.isInstantMatch,
      expired: expired ?? this.expired,
      categoryScore: categoryScore ?? this.categoryScore,
      locationScore: locationScore ?? this.locationScore,
      capacityScore: capacityScore ?? this.capacityScore,
      distance: distance ?? this.distance,
      categoryReasons: categoryReasons ?? this.categoryReasons,
      capacityPercentage: capacityPercentage ?? this.capacityPercentage,
    );
  }
}
