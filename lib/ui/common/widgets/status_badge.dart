import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/listing_status.dart';

/// Badge status listing: warna berbeda untuk tiap status.
/// Badge tersedia berdenyut pelan untuk menandakan listing aktif.
class StatusBadge extends StatelessWidget {
  final ListingStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor.withAlpha(_bgAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _backgroundColor, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status != ListingStatus.expired) ...[
            _PulseDot(color: _backgroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            status.label,
            style: AppTextStyles.badge.copyWith(
              color: _textColor,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  int get _bgAlpha {
    switch (status) {
      case ListingStatus.available:
        return 24;
      case ListingStatus.reserved:
        return 28;
      case ListingStatus.completed:
        return 22;
      case ListingStatus.expired:
        return 26;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case ListingStatus.available:
        return AppColors.kColorSuccess;
      case ListingStatus.reserved:
        return AppColors.kColorWarning;
      case ListingStatus.completed:
        return AppColors.kColorPrimary;
      case ListingStatus.expired:
        return AppColors.kColorDanger;
    }
  }

  Color get _textColor {
    switch (status) {
      case ListingStatus.available:
        return AppColors.kColorSuccess;
      case ListingStatus.reserved:
        return AppColors.kColorWarning;
      case ListingStatus.completed:
        return AppColors.kColorPrimary;
      case ListingStatus.expired:
        return AppColors.kColorDanger;
    }
  }
}

/// Dot denyut untuk status aktif.
class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: CircleAvatar(
          radius: 4.5,
          backgroundColor: widget.color,
        ),
      ),
    );
  }
}
