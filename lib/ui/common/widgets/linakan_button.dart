import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_surfaces.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/anim.dart';

/// Varian tampilan tombol LINAKAN.
enum LinakanButtonVariant { primary, secondary, text }

/// Tombol standar LINAKAN dengan gradient primary dan efek tekan.
class LinakanButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final bool compact;
  final LinakanButtonVariant variant;
  final IconData? icon;

  const LinakanButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.compact = false,
    this.variant = LinakanButtonVariant.primary,
    this.icon,
  });

  const LinakanButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.compact = false,
    this.icon,
  }) : variant = LinakanButtonVariant.secondary;

  const LinakanButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.compact = false,
    this.icon,
  }) : variant = LinakanButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled || isLoading || onPressed == null;
    final bool isPrimary = variant == LinakanButtonVariant.primary;

    final Widget labelWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: isPrimary
                  ? AppColors.kColorOnPrimary
                  : AppColors.kColorPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: compact ? 16 : 18, color: _labelColor(disabled)),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: _labelColor(disabled),
                ),
              ),
            ],
          );

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 15);

    switch (variant) {
      case LinakanButtonVariant.primary:
        return SizedBox(
          width: compact ? null : double.infinity,
          child: PressableScale(
            onTap: disabled ? null : onPressed,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: disabled
                    ? AppColors.kColorMuted.withAlpha(90)
                    : AppColors.kColorPrimary,
                borderRadius: AppRadius.buttonBorder,
                border: Border.all(
                  color: disabled
                      ? AppColors.kColorBorder
                      : AppColors.kColorPrimaryLight,
                ),
                boxShadow: disabled ? null : AppSurfaces.buttonShadow,
              ),
              child: Center(child: labelWidget),
            ),
          ),
        );

      case LinakanButtonVariant.secondary:
        return SizedBox(
          width: compact ? null : double.infinity,
          child: PressableScale(
            onTap: disabled ? null : onPressed,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: AppSurfaces.ivory,
                borderRadius: AppRadius.buttonBorder,
                border: Border.all(
                  color: disabled
                      ? AppColors.kColorBorder
                      : AppColors.kColorSurface,
                ),
                boxShadow: disabled ? null : AppSurfaces.raisedShadow,
              ),
              child: Center(child: labelWidget),
            ),
          ),
        );

      case LinakanButtonVariant.text:
        return TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.kColorPrimary,
            padding: padding,
          ),
          child: labelWidget,
        );
    }
  }

  Color _labelColor(bool disabled) {
    if (disabled) return AppColors.kColorMuted;
    switch (variant) {
      case LinakanButtonVariant.primary:
        return AppColors.kColorOnPrimary;
      case LinakanButtonVariant.secondary:
      case LinakanButtonVariant.text:
        return AppColors.kColorPrimary;
    }
  }
}
