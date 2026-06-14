import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Minimal, gridless balance/history line chart — a curved emerald line with a
/// soft gradient fill. Designed to sit inside the balance hero or any card.
///
/// Pass a series of `values` (oldest → newest). Renders nothing meaningful for
/// fewer than two points, so callers should guard with [hasEnoughData].
class BalanceLineChart extends StatelessWidget {
  const BalanceLineChart({
    super.key,
    required this.values,
    this.color = AppColors.lime,
    this.height = 120,
  });

  final List<double> values;
  final Color color;
  final double height;

  static bool hasEnoughData(List<double> values) => values.length >= 2;

  @override
  Widget build(BuildContext context) {
    if (!hasEnoughData(values)) return SizedBox(height: height);

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    // Pad the range so the line never hugs the top/bottom edge.
    final pad = (maxY - minY).abs() * 0.15 + 1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.28),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single slice of a [CategoryDonut].
class DonutSlice {
  const DonutSlice({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;
}

/// Spending-breakdown donut with a center label, mirroring the reference's
/// "% breakdown" centerpiece. Slice colors fall back to [AppColors.categoryPalette].
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.slices,
    this.centerLabel,
    this.centerValue,
    this.size = 200,
  });

  final List<DonutSlice> slices;
  final String? centerLabel;
  final String? centerValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < slices.length; i++)
        PieChartSectionData(
          value: slices[i].value <= 0 ? 0.0001 : slices[i].value,
          color: slices[i].color ??
              AppColors.categoryPalette[i % AppColors.categoryPalette.length],
          radius: size * 0.16,
          showTitle: total > 0 && slices[i].value / total >= 0.08,
          title: total > 0
              ? '${((slices[i].value / total) * 100).round()}%'
              : '',
          titleStyle: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textOnAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 3,
              centerSpaceRadius: size * 0.30,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
          if (centerValue != null || centerLabel != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (centerValue != null)
                  Text(centerValue!, style: theme.textTheme.titleLarge),
                if (centerLabel != null)
                  Text(
                    centerLabel!,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
