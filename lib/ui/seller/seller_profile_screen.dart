import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/seller_model.dart';
import '../../data/repositories/seller_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/transaction_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/agrarian_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Layar Profil Seller LINAKAN.
///
/// Menggunakan sistem token [AppTokens] — tampilan khas "nota kertas pasar"
/// dengan header solid blue, avatar bersuara stempel terverifikasi, dan
/// menu terkelompok untuk kelengkapan akun & bantuan.
class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    final uid = context.watch<AuthProvider>().currentUserId ?? '';
    final sellerRepo = context.watch<SellerRepository>();
    final seller = sellerRepo.getById(uid);
    final listingProv = context.watch<ListingProvider>();
    final txProv = context.watch<TransactionProvider>();

    final myListings = listingProv.getMyListings(uid);
    final myTx =
        txProv.getMyTransactions(uid).where((t) => t.sellerId == uid).toList();
    final earnings = myTx
        .where((t) => t.status == 'completed')
        .fold<int>(0, (s, t) => s + t.sellerReceives);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTokens.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            slivers: [
              // Header banner + avatar & stempel
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  seller: seller,
                  onLogout: () {
                    context.read<AuthProvider>().logout();
                    context.go('/auth/login');
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Ringkasan transaksi
                    _StatsRow(
                      listings: myListings.length,
                      transactions: myTx.length,
                      earnings: earnings,
                    ),
                    const SizedBox(height: 18),

                    // Tombol Aksi Utama: "Jual Limbah"
                    _JualLimbahButton(
                      onTap: () => context.go('/seller/create-listing'),
                    ),
                    const SizedBox(height: 22),

                    // Kelompok 1: USAHA SAYA
                    const _SectionHeader(title: 'USAHA SAYA'),
                    const SizedBox(height: 8),
                    _buildUsahaCard(context),
                    const SizedBox(height: 20),

                    // Kelompok 2: PENGATURAN AKUN
                    const _SectionHeader(title: 'PENGATURAN AKUN'),
                    const SizedBox(height: 8),
                    _buildAkunCard(context, seller, sellerRepo),
                    const SizedBox(height: 20),

                    // Kelompok 3: BANTUAN & INFO
                    const _SectionHeader(title: 'BANTUAN & INFO'),
                    const SizedBox(height: 8),
                    _buildBantuanCard(context),
                    const SizedBox(height: 26),

                    // Logout Button
                    _LogoutButton(onTap: () {
                      context.read<AuthProvider>().logout();
                      context.go('/auth/login');
                    }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LinakanBottomNav(
        currentIndex: 4,
        onTap: _onNavTap,
        userType: UserType.seller,
      ),
    );
  }

  // --- Cards ---

  Widget _buildUsahaCard(BuildContext context) {
    return _MenuContainer(
      items: [
        _MenuItemData(
          symbol: AgrarianSymbol.harvestCrate,
          label: 'Listing Saya',
          subtitle: 'Kelola semua limbah yang didaftarkan',
          onTap: () => context.go('/seller/listings'),
        ),
        _MenuItemData(
          symbol: AgrarianSymbol.receiptScale,
          label: 'Riwayat Transaksi',
          subtitle: 'Lihat seluruh riwayat penjualan',
          onTap: () => context.go('/seller/transactions'),
        ),
        _MenuItemData(
          symbol: AgrarianSymbol.coinPouch,
          label: 'Dompet LINAKAN',
          subtitle: 'Kelola saldo dan penarikan dana',
          onTap: () => context.go('/wallet'),
        ),
      ],
    );
  }

  Widget _buildAkunCard(
      BuildContext context, SellerModel? seller, SellerRepository repo) {
    return _MenuContainer(
      items: [
        _MenuItemData(
          icon: PhosphorIconsLight.camera,
          label: 'Ubah Foto Profil',
          subtitle: 'Perbarui foto avatar toko Anda',
          onTap: () => _showUpdatePhotoDialog(context, seller, repo),
        ),
        _MenuItemData(
          icon: PhosphorIconsLight.lock,
          label: 'Ganti Password',
          subtitle: 'Amankan akun dengan kata sandi baru',
          onTap: () => _showChangePasswordDialog(context),
        ),
        _MenuItemData(
          icon: PhosphorIconsLight.mapPin,
          label: 'Ganti Alamat',
          subtitle: seller?.location ?? 'Ubah alamat lokasi usaha',
          onTap: () => _showChangeAddressDialog(context, seller, repo),
        ),
      ],
    );
  }

  Widget _buildBantuanCard(BuildContext context) {
    return _MenuContainer(
      items: [
        _MenuItemData(
          icon: PhosphorIconsLight.envelopeSimple,
          label: 'Pusat Bantuan (CS)',
          subtitle: 'Laporkan kendala / kirim email dukungan',
          onTap: () => _showHelpCenterDialog(context),
        ),
        _MenuItemData(
          icon: PhosphorIconsLight.info,
          label: 'Tentang LINAKAN',
          subtitle: 'Misi, cara kerja, dan nilai platform',
          onTap: () => context.go('/seller/about'),
        ),
      ],
    );
  }

  // --- Dialogs ---

  void _showUpdatePhotoDialog(
      BuildContext context, SellerModel? seller, SellerRepository repo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Foto Profil', style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gunakan foto toko yang jelas untuk meningkatkan kepercayaan peternak.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.border),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsLight.checkCircle,
                      color: AppTokens.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistem verifikasi otomatis aktif.',
                      style:
                          AppTextStyles.caption.copyWith(color: AppTokens.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto profil berhasil diperbarui.'),
                  backgroundColor: AppTokens.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.brand,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtr = TextEditingController();
    final newCtr = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password', style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtr,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Lama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtr,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = context.read<AuthProvider>().changePassword(
                    currentPassword: oldCtr.text,
                    newPassword: newCtr.text,
                  );
              if (!result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.error ?? 'Password gagal diperbarui.'),
                    backgroundColor: AppTokens.danger,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diperbarui.'),
                  backgroundColor: AppTokens.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.brand,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        oldCtr.dispose();
        newCtr.dispose();
      });
    });
  }

  void _showChangeAddressDialog(
      BuildContext context, SellerModel? seller, SellerRepository repo) {
    final addrCtr = TextEditingController(text: seller?.location ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Alamat', style: AppTextStyles.heading3),
        content: TextField(
          controller: addrCtr,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Alamat Usaha Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (seller != null && addrCtr.text.trim().isNotEmpty) {
                repo.update(seller.copyWith(location: addrCtr.text.trim()));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alamat berhasil diperbarui.'),
                  backgroundColor: AppTokens.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.brand,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    const String csEmail = 'fairuzharits@gmail.com';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(PhosphorIconsLight.headset, color: AppTokens.brand, size: 22),
            SizedBox(width: 8),
            Text('Pusat Bantuan CS', style: AppTextStyles.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jika mengalami kendala teknis atau kerusakan sistem, hubungi tim support kami via email:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTokens.border),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsLight.envelope,
                      size: 18, color: AppTokens.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      csEmail,
                      style: AppTokens.data
                          .copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsLight.copy, size: 18),
                    tooltip: 'Salin Email',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: csEmail));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email CS berhasil disalin!'),
                          backgroundColor: AppTokens.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        context.go('/seller/dashboard');
        break;
      case 1:
        context.go('/seller/listings');
        break;
      case 2:
        context.go('/seller/transactions');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        context.go('/seller/profile');
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: Banner solid blue + Avatar & Stempel Cap Terverifikasi
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final SellerModel? seller;
  final VoidCallback onLogout;

  const _ProfileHeader({required this.seller, required this.onLogout});

  String get _typeLabel {
    switch (seller?.type) {
      case 'irt':
        return 'IRT (Industri Rumah Tangga)';
      default:
        return 'UMKM Makanan & Kuliner';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = seller?.name ?? 'Seller';
    final bool isVerified = seller?.verified ?? true; // demo: terverifikasi

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Solid Blue Banner (no gradient / image decor)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppTokens.brand,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Profil Usaha',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kColorOnPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(PhosphorIconsLight.signOut,
                        color: AppColors.kColorOnPrimary, size: 20),
                    onPressed: onLogout,
                    tooltip: 'Keluar',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Profile Card — beri jeda 5% lebar layar dari banner.
        Container(
          margin: EdgeInsets.fromLTRB(
            20,
            MediaQuery.sizeOf(context).width * 0.05,
            20,
            0,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: AppTokens.cardRadius,
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.cardShadow,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  // Avatar Initials
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTokens.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTokens.bg, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: AppTokens.displaySmall
                            .copyWith(color: AppColors.kColorOnPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.heading3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _typeLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTokens.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(PhosphorIconsLight.mapPin,
                                size: 12, color: AppTokens.inkMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                seller?.location ?? 'Lokasi belum diset',
                                style: AppTokens.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Signature Element: Stempel "TERVERIFIKASI" rotated
              if (isVerified)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Transform.rotate(
                    angle: -8 * math.pi / 180,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTokens.brand,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTokens.accent, width: 1.5),
                      ),
                      child: Text(
                        'VERIFIED',
                        style: AppTokens.stamp.copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row (Ledger Style)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int listings, transactions, earnings;

  const _StatsRow({
    required this.listings,
    required this.transactions,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          _StatCol(value: '$listings', label: 'Listing'),
          _divider(),
          _StatCol(value: '$transactions', label: 'Transaksi'),
          _divider(),
          _StatCol(
            value: formatRupiah(earnings),
            label: 'Pendapatan',
            isMono: true,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppTokens.border,
      );
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final bool isMono;

  const _StatCol({
    required this.value,
    required this.label,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: isMono
                ? AppTokens.data.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.brand,
                  )
                : GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.ink,
                  ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTokens.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary Call-To-Action: "Jual Limbah"
// ─────────────────────────────────────────────────────────────────────────────

class _JualLimbahButton extends StatelessWidget {
  final VoidCallback onTap;

  const _JualLimbahButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(PhosphorIconsLight.plusCircle,
            size: 20, color: AppColors.kColorOnPrimary),
        label: Text(
          'Jual Limbah Baru',
          style: AppTextStyles.button.copyWith(
            color: AppColors.kColorOnPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.brand,
          shape: const RoundedRectangleBorder(
            borderRadius: AppTokens.cardRadius,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components & Reusables
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTokens.sectionLabel,
      ),
    );
  }
}

class _MenuItemData {
  final IconData? icon;
  final AgrarianSymbol? symbol;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItemData({
    this.icon,
    this.symbol,
    required this.label,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || symbol != null);
}

class _MenuContainer extends StatelessWidget {
  final List<_MenuItemData> items;

  const _MenuContainer({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: item.symbol != null
                    ? AgrarianIcon(
                        item.symbol!,
                        size: 20,
                        color: AppTokens.brand,
                      )
                    : Icon(
                        item.icon,
                        size: 20,
                        color: AppTokens.brand,
                      ),
                title: Text(
                  item.label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: AppTokens.caption,
                ),
                trailing: const Icon(
                  PhosphorIconsLight.caretRight,
                  size: 14,
                  color: AppTokens.inkMuted,
                ),
                onTap: item.onTap,
              ),
              if (idx < items.length - 1)
                const Divider(
                  height: 1,
                  indent: 52,
                  color: AppTokens.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(PhosphorIconsLight.signOut,
            size: 18, color: AppTokens.danger),
        label: Text(
          'Keluar dari Akun',
          style: AppTextStyles.button.copyWith(color: AppTokens.danger),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTokens.danger),
          shape: const RoundedRectangleBorder(
            borderRadius: AppTokens.cardRadius,
          ),
        ),
      ),
    );
  }
}
