import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/storage_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Intro slide data.
class IntroSlide {
  final String imagePath;
  final String title;
  final String subtitle;
  final Color accentColor;

  const IntroSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}

/// Shared full-bleed intro screen for seller & farmer.
/// - imagePath: full-screen background (assets/images/intro/intro1.jpeg..3.jpeg)
/// - onFinish: navigation when user taps "Mulai Gunakan" or swipes up
/// - introSeenKey: storage key to remember if user has seen intro
class IntroScreen extends StatefulWidget {
  final List<IntroSlide> slides;
  final String title; // "LINAKAN" / "LINAKAN Peternak"
  final VoidCallback onFinish;
  final String introSeenKey;

  const IntroScreen({
    super.key,
    required this.slides,
    required this.title,
    required this.onFinish,
    required this.introSeenKey,
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  late final AnimationController _particleController;

  double _verticalDrag = 0;
  bool _navigating = false;

  static const double _swipeThreshold = 80;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    if (_navigating) return;
    _navigating = true;
    StorageService.instance.setBool(widget.introSeenKey, true);
    widget.onFinish();
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() => _verticalDrag += d.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final drag = _verticalDrag;
    setState(() => _verticalDrag = 0);
    if (drag < -_swipeThreshold) {
      _goToDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_currentSlide];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.kColorBackground,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Stack(
              children: [
                // ── Full-bleed background image ──
                Positioned.fill(
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: slide.accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Dark overlay for readability
                Positioned.fill(
                  child: Container(
                    color: AppColors.kColorText.withValues(alpha: 0.42),
                  ),
                ),

                // ── Particle background ──
                _ParticleBackground(controller: _particleController),

                // ── Main content ──
                SafeArea(
                  child: Column(
                    children: [
                      // Header logo
                      _buildHeader(),

                      // Slide area (text overlay on image)
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: widget.slides.length,
                          onPageChanged: (i) =>
                              setState(() => _currentSlide = i),
                          itemBuilder: (_, i) => _buildSlide(
                            widget.slides[i],
                            size,
                            i == _currentSlide,
                          ),
                        ),
                      ),

                      // Bottom: dots + button
                      _buildBottom(slide),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Swipe UP hint
                _SwipeHint(
                  position: SwipeHintPosition.top,
                  label: 'Masuk ke Dashboard',
                  icon: PhosphorIconsLight.caretUp,
                  dragOffset: _verticalDrag,
                  threshold: _swipeThreshold,
                  direction: -1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo/Logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _goToDashboard,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.kColorOnPrimary.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Row(
              children: [
                Text('Lewati',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(width: 2),
                const Icon(PhosphorIconsLight.caretRight,
                    size: 12, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(IntroSlide slide, Size size, bool isActive) {
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 400),
      child: AnimatedScale(
        scale: isActive ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(flex: 2),
              // Text content
              Column(
                children: [
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                      shadows: [
                        Shadow(
                          color: AppColors.kColorText.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                      shadows: [
                        Shadow(
                          color: AppColors.kColorText.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottom(IntroSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          // Dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentSlide ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentSlide
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary CTA button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _goToDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kColorPrimary,
                foregroundColor: AppColors.kColorOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Mulai Gunakan',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.kColorOnPrimary,
                      )),
                  const SizedBox(width: 8),
                  const Icon(PhosphorIconsLight.arrowUp, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Hint gesture
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(PhosphorIconsLight.arrowsDownUp,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Swipe ke atas untuk masuk',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle background (floating circles)
// ---------------------------------------------------------------------------

class _ParticleBackground extends StatelessWidget {
  final AnimationController controller;
  const _ParticleBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(progress: controller.value),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, radius, speed, phase;
  const _Particle(this.x, this.y, this.radius, this.speed, this.phase);
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  static final List<_Particle> _particles = List.generate(14, (i) {
    final rng = math.Random(i * 17 + 3);
    return _Particle(
      rng.nextDouble(),
      rng.nextDouble(),
      rng.nextDouble() * 6 + 3,
      rng.nextDouble() * 0.4 + 0.15,
      rng.nextDouble() * math.pi * 2,
    );
  });

  const _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final dy = -size.height * 0.12 * math.sin(t * math.pi * 2);
      final dx = size.width * 0.02 * math.cos(t * math.pi * 2 + p.phase);

      final x = p.x * size.width + dx;
      final y = p.y * size.height + dy;

      final usePrimary = p.phase < math.pi;
      paint.color = usePrimary
          ? AppColors.kColorPrimary.withAlpha(25)
          : AppColors.kColorAccent.withAlpha(20);

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// SwipeHint widget
// ---------------------------------------------------------------------------

enum SwipeHintPosition { top, bottom }

class _SwipeHint extends StatelessWidget {
  final SwipeHintPosition position;
  final String label;
  final IconData icon;
  final double dragOffset;
  final double threshold;
  final double direction;

  const _SwipeHint({
    required this.position,
    required this.label,
    required this.icon,
    required this.dragOffset,
    required this.threshold,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final activeDrag = direction < 0 ? (dragOffset < -20) : (dragOffset > 20);

    final progress = activeDrag
        ? ((direction < 0 ? -dragOffset : dragOffset) / threshold)
            .clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      top: position == SwipeHintPosition.top ? 0 : null,
      bottom: position == SwipeHintPosition.bottom ? 0 : null,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: activeDrag ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: EdgeInsets.only(
            top: position == SwipeHintPosition.top ? 48 : 8,
            bottom: position == SwipeHintPosition.bottom ? 24 : 8,
          ),
          decoration: BoxDecoration(
            color: (position == SwipeHintPosition.top
                    ? AppColors.kColorPrimary
                    : AppColors.kColorAccent)
                .withAlpha((180 * progress).toInt()),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 6),
                Text(label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
