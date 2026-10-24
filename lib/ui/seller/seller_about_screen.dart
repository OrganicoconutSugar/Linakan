import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

/// Layar "Tentang LINAKAN" — ditampilkan saat user swipe DOWN dari intro.
class SellerAboutScreen extends StatefulWidget {
  const SellerAboutScreen({super.key});

  @override
  State<SellerAboutScreen> createState() => _SellerAboutScreenState();
}

class _SellerAboutScreenState extends State<SellerAboutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            slivers: [
              // ── AppBar dengan gambar ──
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.kColorPrimary,
                leading: IconButton(
                  icon: const Icon(PhosphorIconsLight.caretLeft,
                      color: AppColors.kColorOnPrimary, size: 20),
                  onPressed: () => context.go('/seller/intro'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gambar atau warna
                      Image.asset(
                        'assets/images/profile/linakan_about.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.kColorPrimary,
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 80)),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.kColorPrimary,
                        ),
                      ),
                      // Teks di atas gambar
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tentang LINAKAN',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.kColorOnPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Platform limbah pangan circular economy',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.kColorOnPrimary.withAlpha(190),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Konten ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMission(),
                      const SizedBox(height: 28),
                      _buildValues(),
                      const SizedBox(height: 28),
                      _buildStats(),
                      const SizedBox(height: 28),
                      _buildHowItWorks(),
                      const SizedBox(height: 36),
                      _buildCTA(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------

  Widget _buildMission() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kColorPrimary.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kColorPrimary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('♻️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('Misi Kami',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.kColorPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'LINAKAN hadir untuk mengurangi limbah pangan dari dapur rumah tangga, bakery, dan UMKM makanan — dengan menghubungkannya langsung ke peternak lokal yang membutuhkan pakan ternak berkualitas.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.kColorTextSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValues() {
    final values = [
      (
        PhosphorIconsLight.plant,
        'Berkelanjutan',
        'Setiap kg limbah yang tersalurkan adalah langkah nyata menuju circular economy.'
      ),
      (
        PhosphorIconsLight.lightning,
        'Efisien',
        'Matching otomatis mempertemukan penjual dan peternak dalam hitungan detik.'
      ),
      (
        PhosphorIconsLight.shieldCheck,
        'Terpercaya',
        'Setiap transaksi transparan, terlacak, dan dilindungi sistem LINAKAN.'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nilai Kami', style: AppTextStyles.heading3),
        const SizedBox(height: 16),
        ...values.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.kColorAccentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        v.$1,
                        size: 22,
                        color: AppColors.kColorPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.$2,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.kColorText)),
                        const SizedBox(height: 2),
                        Text(v.$3,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.kColorTextSecondary,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildStats() {
    final stats = [
      ('15 km', 'Radius Matching'),
      ('85%+', 'Threshold Instant Match'),
      ('2 kg', 'Minimum Listing'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kColorBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.kColorShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: stats
            .map((s) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        s.$1,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.$2,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(height: 1.3),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      (
        '1',
        'Daftar & Verifikasi',
        'Buat akun seller, pilih tipe usaha, dan verifikasi nomor HP Anda.'
      ),
      (
        '2',
        'Buat Listing',
        'Upload foto limbah, pilih kategori, dan atur harga.'
      ),
      (
        '3',
        'Tunggu Match',
        'Sistem kami otomatis mencocokkan dengan peternak terdekat.'
      ),
      (
        '4',
        'Terima Pembayaran',
        'Peternak konfirmasi, saldo masuk ke LINAKAN Wallet Anda.'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cara Kerja', style: AppTextStyles.heading3),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.kColorPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s.$1,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kColorOnPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 44,
                      color: AppColors.kColorBorder,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 2),
                      Text(
                        s.$3,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.kColorTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCTA(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => context.go('/seller/dashboard'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kColorPrimary,
          foregroundColor: AppColors.kColorOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mulai Jualan Sekarang',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.kColorOnPrimary,
                )),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsLight.arrowRight, size: 18),
          ],
        ),
      ),
    );
  }
}
