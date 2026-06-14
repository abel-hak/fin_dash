import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/charts.dart';

/// Flagship balance card: a dark elevated surface lifted by a soft emerald
/// glow, with the balance set in the display face and an embedded balance-history
/// sparkline. Optional [trailing] (e.g. a period chip) sits beside the label.
class BalanceHero extends StatelessWidget {
  const BalanceHero({
    super.key,
    required this.label,
    required this.amount,
    required this.currency,
    this.history = const [],
    this.deltaLabel,
    this.deltaPositive = true,
    this.trailing,
  });

  final String label;
  final double amount;
  final String currency;

  /// Balance values oldest → newest for the sparkline. Hidden if < 2 points.
  final List<double> history;
  final String? deltaLabel;
  final bool deltaPositive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;
    final money = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final deltaColor = deltaPositive ? AppColors.lime : AppColors.danger;

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: t.border),
        boxShadow: AppShadows.glow(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: t.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  money.format(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  currency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (deltaLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  deltaPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: deltaColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  deltaLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(color: deltaColor),
                ),
              ],
            ),
          ],
          if (BalanceLineChart.hasEnoughData(history)) ...[
            const SizedBox(height: AppSpacing.m),
            BalanceLineChart(values: history, height: 110),
          ],
        ],
      ),
    );
  }
}
