import '../../core/constants/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

/// Layar masuk LINAKAN — minimalis, latar cream #F2EFE7,
/// aksen biru muda solid dengan motion halus.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill nomor HP tersimpan bila pengguna mencentang "Remember me".
    final remembered = StorageService.instance.getString(
      AppConstants.kKeyRememberedPhone,
    );
    if (remembered != null && remembered.isNotEmpty) {
      _phoneCtr.text = remembered;
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _phoneCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  Future<void> _onMasuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final authProvider = context.read<AuthProvider>();
    final result = authProvider.loginWithEmailOrPhone(
      _phoneCtr.text.trim(),
      _passwordCtr.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Login gagal.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.kColorOnPrimary,
              )),
          backgroundColor: AppColors.kColorDanger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

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
            router.go(provider.authenticatedHomeRoute);
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      body: Stack(
        children: [
          // Full-screen background image
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
          // Ornamen lembut: lingkaran biru transparan
          Positioned(
            top: -90,
            right: -70,
            child: _softOrb(240, AppColors.kColorLime.withAlpha(55))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: -8,
                    end: 10,
                    duration: 6.seconds,
                    curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _softOrb(260, AppColors.kColorPrimary.withAlpha(30))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(
                    begin: -10,
                    end: 12,
                    duration: 7.seconds,
                    curve: Curves.easeInOut),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrand()
                          .animate()
                          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                          .slideY(begin: -0.12, end: 0, duration: 500.ms),
                      const SizedBox(height: 28),
                      _buildFormCard()
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 550.ms)
                          .slideY(
                              begin: 0.08,
                              end: 0,
                              delay: 120.ms,
                              duration: 550.ms),
                      const SizedBox(height: 20),
                      _buildRegisterLink()
                          .animate()
                          .fadeIn(delay: 260.ms, duration: 450.ms)
                          .slideY(
                              begin: 0.15,
                              end: 0,
                              delay: 260.ms,
                              duration: 450.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo/Logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          'LINAKAN',
          style: AppTextStyles.logoTitle.copyWith(
            fontSize: 35,
            fontWeight: FontWeight.w900,
            color: AppColors.kColorBackground,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dari Limbah, Menjadi Berkah.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.kColorSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppSurfaces.ivory,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.kColorBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.kColorShadow,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.kColorLime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MASUK',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.kColorPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Selamat datang kembali', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              'Masukkan nomor HP dan password Anda',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.kColorMuted),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Nomor HP'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneCtr,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.body,
              decoration: _fieldDecoration(
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
              decoration: _fieldDecoration(
                hint: 'Masukkan password',
                prefixIcon: PhosphorIconsLight.lock,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Remember me'),
              ],
            ),
            const SizedBox(height: 16),
            _MasukButton(loading: _loading, onPressed: _onMasuk),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        GestureDetector(
          onTap: () => context.go('/auth/register'),
          child: Text(
            'Daftar sekarang',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.kColorTextSecondary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.kColorTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
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
}

// ---------------------------------------------------------------------------
// Sub-widgets
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

class _MasukButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _MasukButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: loading
            ? AppColors.kColorMuted.withAlpha(90)
            : AppColors.kColorPrimary,
        borderRadius: AppRadius.buttonBorder,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: AppRadius.buttonBorder,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Masuk',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.kColorOnPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(PhosphorIconsLight.arrowRight,
                          color: AppColors.kColorOnPrimary, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
