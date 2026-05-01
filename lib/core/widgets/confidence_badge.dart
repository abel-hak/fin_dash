import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Pill badge that visualizes parser confidence (0-1 scale).
/// >= 0.85 -> high (success)
/// >= 0.6  -> medium (warning)
/// <  0.6  -> low (danger)
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.compact = false,
  });

  /// Expected to be in 0-1. Values outside this range are clamped.
  final double confidence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final value = confidence.clamp(0.0, 1.0);
    final percent = (value * 100).round();
    final theme = Theme.of(context);

    final (Color fg, Color bg, String label) = switch (value) {
      >= 0.85 => (AppColors.success, AppColors.accentSoft, 'High'),
      >= 0.6 => (AppColors.warning, AppColors.warningSoft, 'Medium'),
      _ => (AppColors.danger, AppColors.dangerSoft, 'Low'),
    };

    return Semantics(
      label: 'Confidence $label, $percent percent',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.s : AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              compact ? '$percent%' : '$label · $percent%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
