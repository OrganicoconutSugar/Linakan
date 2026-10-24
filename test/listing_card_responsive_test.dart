import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linakan_app/data/models/listing_model.dart';
import 'package:linakan_app/data/models/listing_status.dart';
import 'package:linakan_app/data/models/match_result_model.dart';
import 'package:linakan_app/data/models/waste_category.dart';
import 'package:linakan_app/ui/common/widgets/listing_card.dart';

void main() {
  testWidgets('ListingCard tidak overflow pada layar mobile sempit',
      (tester) async {
    final listing = ListingModel(
      id: 'listing-responsive',
      sellerId: 'seller1',
      sellerName: 'UMKM Pangan',
      sellerType: 'umkm',
      wasteName: 'Sisa Makanan Olahan Berkualitas',
      category: WasteCategory.sisaMakananOlahan,
      weight: 125.5,
      pricePerKg: 125000,
      totalPrice: 15687500,
      suggestedPrice: 15687500,
      finalPrice: 15687500,
      location: 'Bandung',
      lat: -6.9,
      lng: 107.6,
      pickupAddress: 'Bandung',
      createdAt: DateTime(2026, 10, 24),
      status: ListingStatus.available,
      quality: 'Baik',
    );
    final match = MatchResultModel(
      listing: listing,
      score: 92,
      isInstantMatch: true,
      categoryScore: 100,
      locationScore: 90,
      capacityScore: 80,
      distance: 2.5,
      capacityPercentage: 70,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 288,
              child: ListingCard(
                listing: listing,
                matchResult: match,
                onDetailPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sisa Makanan Olahan Berkualitas'), findsOneWidget);
    expect(find.text('Lihat Detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
