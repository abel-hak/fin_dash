import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Surface container with a subtle border, used as the primary content
/// surface across the dark Finance OS.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.onTap,
    this.borderColor,
    this.color,
    this.radius = AppRadii.l,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    final bg = color ?? (elevated ? t.surfaceElevated : t.surface);
    final border = borderColor ?? t.border;

    final content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.accentSoft,
        highlightColor: AppColors.accentSoft.withValues(alpha: 0.06),
        child: content,
      ),
    );
  }
}
