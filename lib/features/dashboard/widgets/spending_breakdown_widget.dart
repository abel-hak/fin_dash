import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/core/widgets/widgets.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_logic.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Spending-breakdown centerpiece: a Graph/List toggle over the current
/// category breakdown. Graph shows a donut; List shows ranked category rows.
class SpendingBreakdownWidget extends ConsumerStatefulWidget {
  const SpendingBreakdownWidget({super.key});

  @override
  ConsumerState<SpendingBreakdownWidget> createState() =>
      _SpendingBreakdownWidgetState();
}

class _SpendingBreakdownWidgetState
    extends ConsumerState<SpendingBreakdownWidget> {
  int _view = 0; // 0 = Graph, 1 = List

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = ref.watch(parsedTransactionsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Spending', style: theme.textTheme.titleMedium),
              ),
              SegmentedToggle(
                segments: const ['Graph', 'List'],
                selectedIndex: _view,
                onChanged: (i) => setState(() => _view = i),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          transactions.when(
            data: (txList) {
              final slices = DashboardData.categoryBreakdown(txList);
              if (slices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No spending to break down yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              final total = slices.fold<double>(0, (s, e) => s + e.value);
              final money =
                  NumberFormat.compactCurrency(symbol: '', decimalDigits: 1);
              return _view == 0
                  ? Center(
                      child: CategoryDonut(
                        slices: slices.take(6).toList(),
                        centerValue: money.format(total).trim(),
                        centerLabel: 'ETB spent',
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < slices.take(6).length; i++)
                          _CategoryRow(
                            slice: slices[i],
                            total: total,
                            color: AppColors.categoryPalette[
                                i % AppColors.categoryPalette.length],
                          ),
                      ],
                    );
            },
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.slice,
    required this.total,
    required this.color,
  });

  final DonutSlice slice;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? (slice.value / total * 100).round() : 0;
    final money = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(slice.label, style: theme.textTheme.titleSmall),
          ),
          Text('$pct%', style: theme.textTheme.bodySmall),
          const SizedBox(width: AppSpacing.m),
          Text(
            money.format(slice.value),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
