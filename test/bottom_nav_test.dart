import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linakan_app/core/constants/app_colors.dart';
import 'package:linakan_app/core/constants/app_surfaces.dart';
import 'package:linakan_app/providers/auth_provider.dart';
import 'package:linakan_app/ui/common/bottom_nav.dart';

void main() {
  testWidgets('Tab navbar aktif memiliki permukaan timbul dan teks biru',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LinakanBottomNav(
            currentIndex: 0,
            onTap: (_) {},
            userType: UserType.seller,
          ),
        ),
      ),
    );

    final activeContainer = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    final decoration = activeContainer.decoration! as BoxDecoration;
    final activeLabel = tester.widget<Text>(find.text('Dasbor'));

    expect(decoration.color, AppSurfaces.ivory);
    expect(decoration.gradient, isNull);
    expect(activeLabel.style?.color, AppColors.kColorPrimary);
  });
}
