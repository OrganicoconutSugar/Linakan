import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/anim.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Argumen yang dikirim ke OtpScreen via GoRouter extra.
class OtpArgs {
  final String phone;
  final String simulatedOtp;
  final VoidCallback onVerified;
  final VoidCallback? onCancelled;

  const OtpArgs({
    required this.phone,
    required this.simulatedOtp,
    required this.onVerified,
    this.onCancelled,
  });
}

/// Layar verifikasi OTP simulasi LINAKAN.
/// Kode OTP ditampilkan langsung di UI sebagai demo (tidak ada SMS nyata).
class OtpScreen extends StatefulWidget {
  final OtpArgs args;
  const OtpScreen({super.key, required this.args});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _ctrs =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1.0;
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _ctrs) {
      c.dispose();
    }
    for (final f in _foci) {
      f.dispose();
    }
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final authService = AuthService.instance;
    _countdown = authService.hasActiveOtp(widget.args.phone)
        ? authService.otpSecondsRemaining(widget.args.phone)
        : 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otp => _ctrs.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_foci[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
        _verify();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_foci[index - 1]);
    }
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Masukkan 6 digit kode OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final valid = AuthService.instance.verifyOtp(widget.args.phone, _otp);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!valid) {
      setState(() => _error = 'Kode OTP salah atau sudah kadaluarsa.');
      _shakeCtrl
        ..duration = const Duration(milliseconds: 420)
        ..forward(from: 0);
      for (final c in _ctrs) {
        c.clear();
      }
      FocusScope.of(context).requestFocus(_foci[0]);
      return;
    }

    widget.args.onVerified();
  }

  Future<void> _resend() async {
    final newOtp = AuthService.instance.generateOtp(widget.args.phone);
    _startCountdown();
    if (!mounted) return;
    setState(() => _error = null);
    for (final c in _ctrs) {
      c.clear();
    }
    FocusScope.of(context).requestFocus(_foci[0]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode OTP baru: $newOtp  (simulasi demo)'),
        backgroundColor: AppColors.kColorSuccess,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String get _countdownLabel {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 3);
    final mid = '*' * (phone.length - 7);
    return '$start$mid$end';
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskPhone(widget.args.phone);

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) widget.args.onCancelled?.call();
      },
      child: Scaffold(
        backgroundColor: AppColors.kColorBackground,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // AppBar manual
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(PhosphorIconsLight.arrowLeft,
                              color: AppColors.kColorText),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.kColorPrimarySoft,
                          child: Icon(PhosphorIconsLight.lock,
                              color: AppColors.kColorPrimary, size: 18),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeSlideIn(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.kColorSurface.withAlpha(240),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.kColorShadow,
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(PhosphorIconsLight.chatText,
                                    size: 36, color: AppColors.kColorPrimary),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const FadeSlideIn(
                              delay: Duration(milliseconds: 60),
                              child: Text(
                                'Verifikasi OTP',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.displayMedium,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 110),
                              child: Text(
                                'Kode verifikasi dikirim ke\n$maskedPhone',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.kColorTextSecondary),
                              ),
                            ),
                            // Banner simulasi OTP
                            const SizedBox(height: 20),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 150),
                              child: ClipRRect(
                                borderRadius: AppRadius.cardBorder,
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.kColorAccentLight,
                                      borderRadius: AppRadius.cardBorder,
                                      border: Border.all(
                                          color: AppColors.kColorBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(PhosphorIconsLight.info,
                                            color: AppColors.kColorPrimary,
                                            size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Mode Demo — Kode OTP Anda:',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        color: AppColors
                                                            .kColorPrimary,
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.args.simulatedOtp,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.kColorPrimary,
                                                  letterSpacing: 6,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              PhosphorIconsLight.copy,
                                              size: 18,
                                              color: AppColors.kColorPrimary),
                                          tooltip: 'Salin kode',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                text:
                                                    widget.args.simulatedOtp));
                                            for (int i = 0;
                                                i <
                                                    widget.args.simulatedOtp
                                                        .length;
                                                i++) {
                                              _ctrs[i].text =
                                                  widget.args.simulatedOtp[i];
                                            }
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // 6 digit input
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 200),
                              child: ScaleTransition(
                                scale: CurvedAnimation(
                                    parent: _shakeCtrl,
                                    curve: Curves.elasticOut),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                      6,
                                      (i) => _OtpBox(
                                            controller: _ctrs[i],
                                            focusNode: _foci[i],
                                            onChanged: (v) =>
                                                _onDigitChanged(i, v),
                                          )),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.kColorDanger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: PressableScale(
                                onTap: _loading ? null : _verify,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _loading
                                        ? AppColors.kColorMuted.withAlpha(90)
                                        : AppColors.kColorPrimary,
                                    borderRadius: AppRadius.buttonBorder,
                                    boxShadow: _loading
                                        ? null
                                        : const [
                                            BoxShadow(
                                              color: AppColors.kColorShadow,
                                              blurRadius: 12,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.kColorOnPrimary,
                                            ),
                                          )
                                        : const Text('Verifikasi',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.kColorOnPrimary,
                                            )),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: _countdown > 0
                                  ? Text(
                                      'Kirim ulang dalam $_countdownLabel',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.kColorMuted),
                                    )
                                  : TextButton(
                                      onPressed: _resend,
                                      child: Text(
                                        'Kirim ulang kode OTP',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.kColorPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
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
          ],
        ),
      ),
    );
  }
}

/// Kotak digit OTP.
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.displayMedium.copyWith(
          fontSize: 24,
          color: AppColors.kColorText,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.kColorSurface,
          contentPadding: EdgeInsets.zero,
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
                const BorderSide(color: AppColors.kColorPrimary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
