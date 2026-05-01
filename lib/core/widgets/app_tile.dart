import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// List row primitive with consistent spacing, hit target, and semantics.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.dense = false,
    this.padding,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool dense;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padded = padding ??
        EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: dense ? AppSpacing.s : AppSpacing.m,
        );

    final row = Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.m),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle.merge(
                style: theme.textTheme.titleSmall,
                child: title,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                DefaultTextStyle.merge(
                  style: theme.textTheme.bodySmall,
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.m),
          trailing!,
        ],
      ],
    );

    final body = Padding(padding: padded, child: row);
    final wrapped = MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: body,
      ),
    );

    if (onTap == null) return wrapped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accentSoft,
        child: wrapped,
      ),
    );
  }
}
