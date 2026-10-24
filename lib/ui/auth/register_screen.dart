import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/anim.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Layar daftar akun baru LINAKAN.
/// Input: nomor HP, password, nama, alamat (manual / lokasi terkini), role.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  final _confirmCtr = TextEditingController();
  final _nameCtr = TextEditingController();
  final _businessCtr = TextEditingController();
  final _addressCtr = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreeTerms = false;
  bool _fetchingLocation = false;

  UserType _role = UserType.seller;

  // Koordinat — default ke Jakarta Selatan jika tidak di-set
  double _lat = -6.2297;
  double _lng = 106.8419;
  bool _locationSet = false;

  @override
  void dispose() {
    _phoneCtr.dispose();
    _passwordCtr.dispose();
    _confirmCtr.dispose();
    _nameCtr.dispose();
    _businessCtr.dispose();
    _addressCtr.dispose();
    super.dispose();
  }

  // Simulasi "ambil lokasi terkini" — karena prototype web/demo,
  // kita set ke koordinat demo Jakarta Selatan dengan feedback ke user.
  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    // Simulasi delay network
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _lat = -6.2297 + (0.02 * (DateTime.now().millisecond / 1000 - 0.5));
      _lng = 106.8419 + (0.02 * (DateTime.now().second / 60 - 0.5));
      _locationSet = true;
      _fetchingLocation = false;
      if (_addressCtr.text.trim().isEmpty) {
        _addressCtr.text = 'Jakarta Selatan (Lokasi Demo)';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi berhasil diset (simulasi demo).'),
        backgroundColor: AppColors.kColorSuccess,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onDaftar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan.'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
      return;
    }
    setState(() => _loading = true);

    final authProvider = context.read<AuthProvider>();
    final result = authProvider.register(
      phone: _phoneCtr.text.trim(),
      password: _passwordCtr.text,
      name: _nameCtr.text.trim(),
      businessName: _role == UserType.seller ? _businessCtr.text.trim() : null,
      address: _addressCtr.text.trim(),
      lat: _lat,
      lng: _lng,
      role: _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Pendaftaran gagal.'),
          backgroundColor: AppColors.kColorDanger,
        ),
      );
      return;
    }

    // Register berhasil — kirim OTP simulasi
    final otp = AuthService.instance.generateOtp(_phoneCtr.text.trim());
    final provider = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    if (!mounted) return;

    context.push('/auth/otp',
        extra: OtpArgs(
          phone: _phoneCtr.text.trim(),
          simulatedOtp: otp,
          onCancelled: provider.cancelPendingAuthentication,
          onVerified: () {
            if (!provider.completeOtpVerification()) return;
            final userType = provider.currentUserType;
            if (userType == UserType.farmer) {
              // Peternak baru → intro dulu (intro → onboarding → dashboard)
              router.go('/farmer/intro');
            } else {
              // Seller baru → intro dulu
              router.go('/seller/intro');
            }
          },
        ));
  }

  Widget _softOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.kColorMuted),
      prefixIcon: Icon(prefixIcon, color: AppColors.kColorMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.kColorSurfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide:
            const BorderSide(color: AppColors.kColorPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.fieldBorder,
        borderSide: const BorderSide(color: AppColors.kColorDanger, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.kColorBackground,
        body: Stack(
          children: [
            // Full-screen background image (same as login)
            Positioned.fill(
              child: Image.asset(
                'assets/images/intro/bglogin.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay for readability
            Positioned.fill(
              child: Container(
                color: AppColors.kColorText.withValues(alpha: 0.35),
              ),
            ),
            // Ornamen lembut
            Positioned(
              top: -90,
              right: -70,
              child: _softOrb(240, AppColors.kColorLime.withAlpha(55)),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: _softOrb(260, AppColors.kColorPrimary.withAlpha(30)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: Text(
                            'Sign Up',
                            style: AppTextStyles.displayMedium
                                .copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: Text(
                            'Please provide the detail below to create your account',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.kColorSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: _RolePicker(
                            selected: _role,
                            onChanged: (r) => setState(() => _role = r),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 240),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppSurfaces.ivory,
                              boxShadow: AppSurfaces.raisedShadow,
                              borderRadius: AppRadius.cardBorder,
                              border: Border.all(color: AppColors.kColorBorder),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _FieldLabel('Nama Lengkap'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _nameCtr,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: AppTextStyles.body,
                                    decoration: _inputDecoration(
                                      hint: _role == UserType.seller
                                          ? 'Nama lengkap Anda'
                                          : 'Nama lengkap Anda',
                                      prefixIcon: PhosphorIconsLight.user,
                                    ),
                                    validator: AuthService.validateName,
                                  ),
                                  if (_role == UserType.seller) ...[
                                    const SizedBox(height: 16),
                                    const _FieldLabel('Nama Usaha'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _businessCtr,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      style: AppTextStyles.body,
                                      decoration: _inputDecoration(
                                        hint: 'Nama usaha / toko Anda',
                                        prefixIcon:
                                            PhosphorIconsLight.storefront,
                                      ),
                                      validator: (v) {
                                        if (_role == UserType.seller &&
                                            (v == null || v.trim().isEmpty)) {
                                          return 'Nama usaha tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  const _FieldLabel('Nomor HP'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _phoneCtr,
                                    keyboardType: TextInputType.phone,
                                    style: AppTextStyles.body,
                                    decoration: _inputDecoration(
                                      hint: '08123456789',
                                      prefixIcon: PhosphorIconsLight.phone,
                                    ),
                                    validator: AuthService.validatePhone,
                                  ),
                                  const SizedBox(height: 16),
                                  const _FieldLabel('Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordCtr,
                                    obscureText: _obscurePassword,
                                    style: AppTextStyles.body,
                                    decoration: _inputDecoration(
                                      hint: 'Minimal 6 karakter',
                                      prefixIcon: PhosphorIconsLight.lock,
                                      suffix: IconButton(
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                        icon: Icon(
                                          _obscurePassword
                                              ? PhosphorIconsLight.eye
                                              : PhosphorIconsLight.eyeClosed,
                                          color: AppColors.kColorMuted,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: AuthService.validatePassword,
                                  ),
                                  const SizedBox(height: 16),
                                  const _FieldLabel('Konfirmasi Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _confirmCtr,
                                    obscureText: _obscureConfirm,
                                    style: AppTextStyles.body,
                                    decoration: _inputDecoration(
                                      hint: 'Ulangi password',
                                      prefixIcon: PhosphorIconsLight.lock,
                                      suffix: IconButton(
                                        onPressed: () => setState(() =>
                                            _obscureConfirm = !_obscureConfirm),
                                        icon: Icon(
                                          _obscureConfirm
                                              ? PhosphorIconsLight.eye
                                              : PhosphorIconsLight.eyeClosed,
                                          color: AppColors.kColorMuted,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v != _passwordCtr.text
                                        ? 'Password tidak cocok'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const _FieldLabel('Alamat'),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _addressCtr,
                                          maxLines: 2,
                                          style: AppTextStyles.body,
                                          decoration: _inputDecoration(
                                            hint:
                                                'Jl. Contoh No.1, Kecamatan, Kota',
                                            prefixIcon:
                                                PhosphorIconsLight.mapPin,
                                          ).copyWith(alignLabelWithHint: true),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Alamat tidak boleh kosong';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _fetchingLocation
                                            ? null
                                            : _getCurrentLocation,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppColors.kColorPrimary,
                                          padding: const EdgeInsets.all(6),
                                          minimumSize: const Size(36, 36),
                                        ),
                                        child: _fetchingLocation
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : Icon(
                                                _locationSet
                                                    ? PhosphorIconsLight.mapPin
                                                    : PhosphorIconsLight.target,
                                                size: 18,
                                                color: _locationSet
                                                    ? AppColors.kColorSuccess
                                                    : AppColors.kColorPrimary,
                                              ),
                                      ),
                                    ],
                                  ),
                                  if (_locationSet) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Koordinat: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.kColorSuccess),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreeTerms,
                                        onChanged: (v) => setState(
                                            () => _agreeTerms = v ?? false),
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                            'Saya setuju Syarat & Ketentuan.'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _DaftarButton(
                                      loading: _loading, onPressed: _onDaftar),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => context.go('/auth/login'),
                                    child: Text(
                                      'Kembali ke Masuk',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.kColorPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium
          .copyWith(color: AppColors.kColorTextSecondary),
    );
  }
}

class _DaftarButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _DaftarButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: PressableScale(
        onTap: loading ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: loading
                ? AppColors.kColorMuted.withAlpha(90)
                : AppColors.kColorPrimary,
            borderRadius: AppRadius.buttonBorder,
            boxShadow: loading
                ? null
                : const [
                    BoxShadow(
                      color: AppColors.kColorShadow,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.kColorOnPrimary,
                    ),
                  )
                : Text(
                    'Daftar & Verifikasi OTP',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.kColorOnPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  final UserType selected;
  final ValueChanged<UserType> onChanged;
  const _RolePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: PhosphorIconsLight.storefront,
            label: 'Seller',
            subtitle: '',
            selected: selected == UserType.seller,
            onTap: () => onChanged(UserType.seller),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon: PhosphorIconsLight.plant,
            label: 'Peternak',
            subtitle: '',
            selected: selected == UserType.farmer,
            onTap: () => onChanged(UserType.farmer),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.kColorPrimarySoft : AppColors.kColorSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.kColorPrimary
                : AppColors.kColorBorder.withAlpha(80),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color:
                    selected ? AppColors.kColorPrimary : AppColors.kColorMuted),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.heading3.copyWith(
                  color:
                      selected ? AppColors.kColorPrimary : AppColors.kColorText,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
