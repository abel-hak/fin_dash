import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Compact metric tile (e.g. weekly income / expenses). An icon chip, a label,
/// the value, and an optional small delta line — token-driven, sits two-up in a
/// Row on the dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.delta,
    this.tone = StatTone.neutral,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? delta;
  final StatTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;

    final accent = switch (tone) {
      StatTone.positive => AppColors.success,
      StatTone.negative => AppColors.danger,
      StatTone.neutral => AppColors.accent,
    };

    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.s),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: t.textPrimary),
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              delta!,
              style: theme.textTheme.labelSmall?.copyWith(color: accent),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.l),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.l),
        splashColor: AppColors.accentSoft,
        child: content,
      ),
    );
  }
}

enum StatTone { positive, negative, neutral }
