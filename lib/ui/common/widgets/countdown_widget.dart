import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/waste_category.dart';
import '../../../domain/shelf_life_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Widget hitung mundur masa simpan listing.
/// Diperbarui setiap 1 menit; berdenyut ketika masa simpan hampir habis.
class CountdownWidget extends StatefulWidget {
  final WasteCategory category;
  final DateTime createdAt;

  const CountdownWidget({
    super.key,
    required this.category,
    required this.createdAt,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with SingleTickerProviderStateMixin {
  final ShelfLifeService _shelfLifeService = ShelfLifeService();
  late Timer _timer;
  late Duration _remaining;
  late ShelfLifeStatus _status;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _update();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _update();
    });
  }

  void _update() {
    final expiry = _shelfLifeService.getExpiryDate(
      widget.category,
      widget.createdAt,
    );
    setState(() {
      _remaining = expiry.difference(DateTime.now());
      _status = _shelfLifeService.getStatus(widget.category, widget.createdAt);
    });
    // Denyut hanya saat mendesak (expiring soon / expired).
    if (_status != ShelfLifeStatus.fresh && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (_status == ShelfLifeStatus.fresh && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _remaining.isNegative
        ? 'Kadaluarsa'
        : _shelfLifeService.formatTimeRemaining(_remaining);

    final isUrgent = _status == ShelfLifeStatus.expiringSoon ||
        _status == ShelfLifeStatus.expired;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUrgent)
          FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
            ),
            child: Icon(PhosphorIconsLight.clock, size: 14, color: _textColor),
          )
        else
          Icon(PhosphorIconsLight.clock, size: 14, color: _textColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: _textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color get _textColor {
    switch (_status) {
      case ShelfLifeStatus.fresh:
        return AppColors.kColorSuccess;
      case ShelfLifeStatus.expiringSoon:
        return AppColors.kColorWarning;
      case ShelfLifeStatus.expired:
        return AppColors.kColorDanger;
    }
  }
}
