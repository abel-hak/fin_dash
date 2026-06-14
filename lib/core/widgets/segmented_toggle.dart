import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Pill segmented control (e.g. "Graph / List"). The selected segment fills with
/// the lime highlight; the track is a rounded elevated surface. Generic over the
/// number of [segments].
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            GestureDetector(
              onTap: () {
                if (i == selectedIndex) return;
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: i == selectedIndex ? AppColors.lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  segments[i],
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: i == selectedIndex
                        ? AppColors.textOnAccent
                        : t.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
