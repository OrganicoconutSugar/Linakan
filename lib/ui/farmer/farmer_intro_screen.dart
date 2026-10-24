import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../common/intro_screen.dart';

/// Intro khusus peternak — full-bleed background images (intro1–3.jpeg).
class FarmerIntroScreen extends StatelessWidget {
  const FarmerIntroScreen({super.key});

  static const List<IntroSlide> _slides = [
    IntroSlide(
      imagePath: 'assets/images/intro/intro1.jpeg',
      title: 'Limbah Pangan\nJadi Pakan Berkualitas',
      subtitle:
          'LINAKAN menyediakan limbah pangan segar dan bernutrisi untuk ternak Anda.',
      accentColor: AppColors.kColorPrimary,
    ),
    IntroSlide(
      imagePath: 'assets/images/intro/intro2.jpeg',
      title: 'Matching\nCerdas & Terdekat',
      subtitle:
          'Dapatkan limbah segar dari seller terdekat, hanya dalam radius 15 km.',
      accentColor: AppColors.kColorAccent,
    ),
    IntroSlide(
      imagePath: 'assets/images/intro/intro3.jpeg',
      title: 'Kelola Transaksi\nDengan Mudah',
      subtitle:
          'Terima order, pantau kebutuhan pakan, dan bayar sesuai kapasitas Anda.',
      accentColor: AppColors.kColorPrimary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntroScreen(
      slides: _slides,
      title: 'LINAKAN Peternak',
      onFinish: () {
        StorageService.instance.setBool(AppConstants.kKeyIntroSeenFarmer, true);
        context.go('/farmer/onboarding');
      },
      introSeenKey: AppConstants.kKeyIntroSeenFarmer,
    );
  }
}
