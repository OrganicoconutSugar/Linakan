import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_surfaces.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/notification_provider.dart';
import 'agrarian_icon.dart';

/// Reusable wallet‑style header for dashboard pages.
/// - No background; the parent dashboard supplies a green gradient layer.
/// - Header contents: greeting, value, badge, action buttons.
class WalletHeader extends StatelessWidget {
  final String valueLabel;
  final String value;
  final String greetingName;
  final String? badge;
  final List<HeaderAction> actions;
  final VoidCallback onLogout;
  final VoidCallback? onTopUp;

  const WalletHeader({
    super.key,
    required this.valueLabel,
    required this.value,
    required this.greetingName,
    this.badge,
    required this.actions,
    required this.onLogout,
    this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = (MediaQuery.sizeOf(context).width * 0.20)
        .clamp(56.0, 72.0)
        .toDouble();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo/Logo.png',
                  key: const ValueKey('dashboard-logo'),
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => AgrarianIcon(
                    AgrarianSymbol.sprout,
                    size: logoSize * 0.78,
                    color: AppColors.kColorOnPrimary,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'LINAKAN',
                  style: AppTextStyles.logoTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kColorOnPrimary,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                const _NotificationBell(),
                IconButton(
                  icon: const Icon(PhosphorIconsLight.signOut,
                      color: AppColors.kColorOnPrimary, size: 20),
                  tooltip: 'Keluar',
                  onPressed: onLogout,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              key: const ValueKey('dashboard-wallet-balance'),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kColorSurface.withAlpha(86),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.kColorSurface.withAlpha(150),
                ),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.kColorShadow,
                      blurRadius: 18,
                      offset: Offset(0, 8)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valueLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.kColorOnPrimary.withAlpha(210),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          key: const ValueKey('dashboard-wallet-amount'),
                          style: AppTextStyles.displayMedium.copyWith(
                            fontSize: 28,
                            color: AppColors.kColorOnPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (onTopUp != null) ...[
                          const SizedBox(height: 8),
                          Semantics(
                            button: true,
                            label: 'Top up saldo',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const ValueKey('wallet-header-top-up'),
                                onTap: onTopUp,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.kColorSurface,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        PhosphorIconsLight.plus,
                                        color: AppColors.kColorPrimary,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Top Up',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.kColorPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const AgrarianIcon(
                    AgrarianSymbol.coinPouch,
                    color: AppColors.kColorOnPrimary,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang,',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.kColorOnPrimary.withAlpha(190),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        greetingName,
                        style: AppTextStyles.displayMedium.copyWith(
                          fontSize: 22,
                          color: AppColors.kColorOnPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kColorSurface.withAlpha(80),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.kColorSurface.withAlpha(150),
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: AppTextStyles.badge.copyWith(
                        color: AppColors.kColorOnPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: actions.map((a) => _HeaderButton(action: a)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HeaderAction {
  final String label;
  final IconData icon;
  final AgrarianSymbol? symbol;
  final VoidCallback onTap;
  final bool primary;
  const HeaderAction(
      {required this.label,
      required this.icon,
      this.symbol,
      required this.onTap,
      this.primary = false});
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  void _showBottomSheet(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final notifications = provider.notifications;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppSurfaces.ivory,
          boxShadow: AppSurfaces.raisedShadow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.kColorBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifikasi', style: AppTextStyles.heading3),
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      provider.markAllRead();
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Tandai semua dibaca',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.kColorPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(PhosphorIconsLight.bellSimple,
                                size: 48, color: AppColors.kColorMuted),
                            const SizedBox(height: 12),
                            Text('Belum ada notifikasi',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.kColorMuted)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = notifications[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: n.isRead
                                ? AppColors.kColorMuted.withAlpha(50)
                                : AppColors.kColorPrimary.withAlpha(100),
                            child: Icon(
                              n.type == 'match'
                                  ? PhosphorIconsLight.lightning
                                  : n.type == 'transaction'
                                      ? PhosphorIconsLight.receipt
                                      : PhosphorIconsLight.info,
                              color: n.isRead
                                  ? AppColors.kColorMuted
                                  : AppColors.kColorPrimary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: n.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            n.message,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.kColorTextSecondary),
                          ),
                          trailing: Text(
                            '${n.createdAt}'
                                .substring(0, 16)
                                .replaceAll('T', ' '),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.kColorMuted),
                          ),
                          onTap: () {
                            provider.markRead(n.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, provider, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(PhosphorIconsLight.bell,
                  color: AppColors.kColorOnPrimary, size: 22),
              tooltip: 'Notifikasi',
              onPressed: () => _showBottomSheet(context),
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.kColorDanger,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  alignment: Alignment.center,
                  child: Text(
                    provider.unreadCount > 99
                        ? '99+'
                        : provider.unreadCount.toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.kColorOnPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final HeaderAction action;
  const _HeaderButton({required this.action});
  @override
  Widget build(BuildContext context) {
    final isPrimary = action.primary;
    final bg = isPrimary
        ? AppColors.kColorSurface
        : AppColors.kColorSurface.withAlpha(92);
    final fg = isPrimary ? AppColors.kColorPrimary : AppColors.kColorOnPrimary;
    return Expanded(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? AppSurfaces.ivory : bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kColorSurface.withAlpha(160)),
            boxShadow: AppSurfaces.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              action.symbol == null
                  ? Icon(action.icon, size: 20, color: fg)
                  : AgrarianIcon(action.symbol!, size: 20, color: fg),
              const SizedBox(height: 4),
              Text(action.label,
                  style: AppTextStyles.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
