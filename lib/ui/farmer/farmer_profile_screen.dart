import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/farmer_model.dart';
import '../../data/repositories/farmer_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../common/bottom_nav.dart';
import '../common/widgets/agrarian_icon.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    final uid = context.watch<AuthProvider>().currentUserId ?? '';
    final farmerRepo = context.read<FarmerRepository>();
    final farmer = farmerRepo.getById(uid);
    final txProv = context.watch<TransactionProvider>();

    final myTx =
        txProv.getMyTransactions(uid).where((t) => t.farmerId == uid).toList();
    final completed = myTx.where((t) => t.status == 'completed').length;
    final spending = myTx
        .where((t) => t.status == 'completed')
        .fold<int>(0, (s, t) => s + t.farmerPays);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.kColorBackground,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  name: farmer?.name ?? 'Peternak',
                  phone: farmer?.phone ?? '-',
                  location: farmer?.location ?? '-',
                  livestock: farmer?.livestock ?? const [],
                  capacity: farmer?.capacity ?? 0,
                  isVerified: farmer?.verified ?? false,
                  onLogout: () {
                    context.read<AuthProvider>().logout();
                    context.go('/auth/login');
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsRow(
                      transactions: myTx.length,
                      completed: completed,
                      spending: spending,
                    ),
                    const SizedBox(height: 22),
                    const Text('AKTIVITAS', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    _buildActivityCard(context),
                    const SizedBox(height: 20),
                    const Text('PENGATURAN AKUN',
                        style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    _buildAccountCard(context, farmer, farmerRepo),
                    const SizedBox(height: 20),
                    _AboutLinakanCard(
                      onTap: () => context.go('/seller/about'),
                    ),
                    const SizedBox(height: 20),
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
        userType: UserType.farmer,
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    final items = [
      _MenuItem(
        symbol: AgrarianSymbol.exchange,
        label: 'Instant Match',
        subtitle: 'Lihat listing yang cocok untuk ternak Anda',
        onTap: () => context.go('/farmer/matches'),
      ),
      _MenuItem(
        symbol: AgrarianSymbol.market,
        label: 'Pasar Limbah',
        subtitle: 'Jelajahi semua listing tersedia',
        onTap: () => context.go('/farmer/marketplace'),
      ),
      _MenuItem(
        symbol: AgrarianSymbol.receiptScale,
        label: 'Riwayat Transaksi',
        subtitle: 'Lihat semua transaksi Anda',
        onTap: () => context.go('/farmer/transactions'),
      ),
      _MenuItem(
        symbol: AgrarianSymbol.coinPouch,
        label: 'Dompet LINAKAN',
        subtitle: 'Kelola saldo dan riwayat dompet',
        onTap: () => context.go('/wallet'),
      ),
    ];

    return _buildMenuContainer(items);
  }

  Widget _buildAccountCard(
    BuildContext context,
    FarmerModel? farmer,
    FarmerRepository repo,
  ) {
    return _buildMenuContainer([
      _MenuItem(
        icon: PhosphorIconsLight.camera,
        label: 'Ubah Foto Profil',
        subtitle: 'Perbarui foto profil peternakan Anda',
        onTap: () => _showUpdatePhotoDialog(context),
      ),
      _MenuItem(
        icon: PhosphorIconsLight.lock,
        label: 'Ganti Password',
        subtitle: 'Amankan akun dengan kata sandi baru',
        onTap: () => _showChangePasswordDialog(context),
      ),
      _MenuItem(
        icon: PhosphorIconsLight.mapPin,
        label: 'Ganti Alamat',
        subtitle: farmer?.location ?? 'Ubah alamat peternakan',
        onTap: () => _showChangeAddressDialog(context, farmer, repo),
      ),
    ]);
  }

  Widget _buildMenuContainer(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: item.symbol != null
                    ? AgrarianIcon(
                        item.symbol!,
                        color: AppColors.kColorPrimary,
                        size: 22,
                      )
                    : Icon(
                        item.icon,
                        color: AppColors.kColorPrimary,
                        size: 22,
                      ),
                title: Text(item.label, style: AppTextStyles.bodyMedium),
                subtitle: Text(item.subtitle, style: AppTextStyles.caption),
                trailing: const Icon(PhosphorIconsLight.caretRight,
                    size: 14, color: AppColors.kColorMuted),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1, indent: 16, color: AppColors.kColorBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showUpdatePhotoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Ubah Foto Profil',
          style: AppTextStyles.heading3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gunakan foto peternakan yang jelas agar profil Anda mudah dikenali.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kColorBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kColorBorder),
              ),
              child: const Row(
                children: [
                  Icon(
                    PhosphorIconsLight.camera,
                    color: AppColors.kColorPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistem verifikasi foto otomatis aktif.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto profil berhasil diperbarui.'),
                  backgroundColor: AppColors.kColorSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorPrimary,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Ganti Password',
          style: AppTextStyles.heading3,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Lama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ulangi Password Baru',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPassword = newController.text;
              if (newPassword != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konfirmasi password belum sama.'),
                    backgroundColor: AppColors.kColorDanger,
                  ),
                );
                return;
              }

              final result = context.read<AuthProvider>().changePassword(
                    currentPassword: oldController.text,
                    newPassword: newPassword,
                  );
              if (!result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.error ?? 'Password gagal diperbarui.'),
                    backgroundColor: AppColors.kColorDanger,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diperbarui.'),
                  backgroundColor: AppColors.kColorSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorPrimary,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        oldController.dispose();
        newController.dispose();
        confirmController.dispose();
      });
    });
  }

  void _showChangeAddressDialog(
    BuildContext context,
    FarmerModel? farmer,
    FarmerRepository repo,
  ) {
    final addressController = TextEditingController(
      text: farmer?.location ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Ganti Alamat',
          style: AppTextStyles.heading3,
        ),
        content: TextField(
          controller: addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alamat Peternakan Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final address = addressController.text.trim();
              if (farmer == null || address.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alamat tidak boleh kosong.'),
                    backgroundColor: AppColors.kColorDanger,
                  ),
                );
                return;
              }

              repo.update(farmer.copyWith(location: address));
              setState(() {});
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alamat berhasil diperbarui.'),
                  backgroundColor: AppColors.kColorSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kColorPrimary,
              foregroundColor: AppColors.kColorOnPrimary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        addressController.dispose,
      );
    });
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        context.go('/farmer/dashboard');
        break;
      case 1:
        context.go('/farmer/matches');
        break;
      case 2:
        context.go('/farmer/marketplace');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        context.go('/farmer/profile');
        break;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name, phone, location;
  final List<String> livestock;
  final double capacity;
  final bool isVerified;
  final VoidCallback onLogout;

  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.location,
    required this.livestock,
    required this.capacity,
    required this.isVerified,
    required this.onLogout,
  });

  String get _livestockLabel {
    if (livestock.isEmpty) return 'Peternak';
    return livestock.map((e) => e[0].toUpperCase() + e.substring(1)).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Solid Blue Banner with rounded bottom
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.kColorPrimary,
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
                    'Profil Peternak',
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
                  ),
                ],
              ),
            ),
          ),
        ),

        // Profile Card – beri jeda 5% lebar layar dari banner.
        Container(
          margin: EdgeInsets.fromLTRB(
            20,
            MediaQuery.sizeOf(context).width * 0.05,
            20,
            0,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppSurfaces.ivory,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kColorBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.kColorShadow,
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.kColorPrimary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kColorOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.heading3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified)
                          const Icon(
                            PhosphorIconsLight.shieldCheck,
                            color: AppColors.kColorSuccess,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_livestockLabel • ${capacity.toStringAsFixed(0)} kg/minggu',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.kColorPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsLight.mapPin,
                          size: 12,
                          color: AppColors.kColorMuted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsLight.phone,
                          size: 12,
                          color: AppColors.kColorMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            phone,
                            style: AppTextStyles.caption,
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
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int transactions, completed, spending;

  const _StatsRow({
    required this.transactions,
    required this.completed,
    required this.spending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        boxShadow: AppSurfaces.raisedShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kColorBorder),
      ),
      child: Row(
        children: [
          _StatItem(
              value: '$transactions',
              label: 'Transaksi',
              color: AppColors.kColorPrimary),
          _vDivider(),
          _StatItem(
              value: '$completed',
              label: 'Selesai',
              color: AppColors.kColorSuccess),
          _vDivider(),
          _StatItem(
              value: formatRupiah(spending),
              label: 'Pengeluaran',
              color: AppColors.kColorPrimary,
              small: true),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        color: AppColors.kColorBorder,
      );
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool small;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: small ? 14 : 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AboutLinakanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AboutLinakanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kColorPrimary.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kColorPrimary.withAlpha(40)),
        ),
        child: const Row(
          children: [
            Icon(PhosphorIconsLight.leaf,
                color: AppColors.kColorPrimary, size: 24),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tentang LINAKAN', style: AppTextStyles.bodyMedium),
                  Text(
                    'Misi, cara kerja, dan nilai platform',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(PhosphorIconsLight.caretRight,
                size: 14, color: AppColors.kColorMuted),
          ],
        ),
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
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(PhosphorIconsLight.signOut,
            size: 18, color: AppColors.kColorDanger),
        label: Text(
          'Keluar',
          style: AppTextStyles.button.copyWith(color: AppColors.kColorDanger),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.kColorDanger),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData? icon;
  final AgrarianSymbol? symbol;
  final String label, subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    this.icon,
    this.symbol,
    required this.label,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || symbol != null);
}
