import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../common/intro_screen.dart';

/// Intro khusus seller (UMKM/IRT) — full-bleed background images (intro1–3.jpeg).
class SellerIntroScreen extends StatelessWidget {
  const SellerIntroScreen({super.key});

  static const List<IntroSlide> _slides = [
    IntroSlide(
      imagePath: 'assets/images/intro/intro1.jpeg',
      title: 'Limbah Pangan\nJadi Bernilai',
      subtitle:
          'Jual limbah pangan Anda langsung ke peternak lokal — tanpa perantara.',
      accentColor: AppColors.kColorPrimary,
    ),
    IntroSlide(
      imagePath: 'assets/images/intro/intro2.jpeg',
      title: 'Matching\nCerdas & Cepat',
      subtitle:
          'Sistem kami mencocokkan limbah Anda dengan peternak terdekat secara otomatis. Radius maksimal 15 km.',
      accentColor: AppColors.kColorAccent,
    ),
    IntroSlide(
      imagePath: 'assets/images/intro/intro3.jpeg',
      title: 'Kelola Penjualan\nDengan Mudah',
      subtitle:
          'Buat listing, pantau status, terima pembayaran, dan tarik dana — semua dalam satu aplikasi.',
      accentColor: AppColors.kColorPrimary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntroScreen(
      slides: _slides,
      title: 'LINAKAN',
      onFinish: () {
        StorageService.instance.setBool(AppConstants.kKeyIntroSeen, true);
        context.go('/seller/dashboard');
      },
      introSeenKey: AppConstants.kKeyIntroSeen,
    );
  }
}
