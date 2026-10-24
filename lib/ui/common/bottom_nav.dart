import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_surfaces.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import 'widgets/agrarian_icon.dart';

/// Bottom navigation bar — navbar melayang: *pill* shape, glass‑blur
/// latar belakang, dan highlight putih-abu pada tab aktif.
/// Dipasang di dashboard seller & farmer (see reference image).
class LinakanBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final UserType userType;

  const LinakanBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userType,
  });

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final items = userType == UserType.seller ? _sellerItems : _farmerItems;
    final mq = MediaQuery.of(context);
    // Let the bar breathe above the keyboard on small screens.
    final bottomPadding = mq.viewInsets.bottom == 0
        ? mq.padding.bottom + 14
        : mq.padding.bottom + 24;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: bottomPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: _barHeight,
              width: mq.size.width,
              decoration: BoxDecoration(
                color: AppSurfaces.glass,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xEFFFFFFF),
                  width: 1.3,
                ),
                boxShadow: AppSurfaces.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final active = i == currentIndex;
                  final color =
                      active ? AppColors.kColorPrimary : AppColors.kColorMuted;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(20),
                      overlayColor: WidgetStateProperty.resolveWith(
                        (s) => AppColors.kColorPrimarySoft.withAlpha(120),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppSurfaces.ivory : null,
                          borderRadius: BorderRadius.circular(active ? 16 : 12),
                          border: active
                              ? Border.all(
                                  color: AppColors.kColorSurface.withAlpha(220),
                                )
                              : null,
                          boxShadow: active ? AppSurfaces.softShadow : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AgrarianIcon(
                              item.symbol,
                              size: active ? 22 : 20,
                              color: color,
                              active: active,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: AppTextStyles.caption.copyWith(
                                color: color,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const List<_NavItem> _sellerItems = [
    _NavItem(AgrarianSymbol.barn, 'Dasbor'),
    _NavItem(AgrarianSymbol.harvestCrate, 'Daftar'),
    _NavItem(AgrarianSymbol.receiptScale, 'Transaksi'),
    _NavItem(AgrarianSymbol.coinPouch, 'Dompet'),
    _NavItem(AgrarianSymbol.grower, 'Profil'),
  ];

  static const List<_NavItem> _farmerItems = [
    _NavItem(AgrarianSymbol.barn, 'Dasbor'),
    _NavItem(AgrarianSymbol.exchange, 'Match'),
    _NavItem(AgrarianSymbol.market, 'Pasar'),
    _NavItem(AgrarianSymbol.coinPouch, 'Dompet'),
    _NavItem(AgrarianSymbol.grower, 'Profil'),
  ];
}

class _NavItem {
  final AgrarianSymbol symbol;
  final String label;
  const _NavItem(this.symbol, this.label);
}
