import 'package:flutter/material.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Solid placeholder block with a subtle shimmer animation, used during
/// async loading. Avoids the cheap "spinner-only" feel.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadii.s,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2.0 * value, 0),
                end: Alignment(1.0 + 2.0 * value, 0),
                colors: [
                  t.skeletonBase,
                  t.skeletonHighlight,
                  t.skeletonBase,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Stack of skeleton rows to mirror an upcoming list layout.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 64,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
      itemBuilder: (_, __) => Container(
        height: itemHeight,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppRadii.l),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            const SkeletonBox(height: 40, width: 40, radius: AppRadii.m),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 12, width: 140),
                  SizedBox(height: 8),
                  SkeletonBox(height: 10, width: 90),
                ],
              ),
            ),
            const SkeletonBox(height: 16, width: 60),
          ],
        ),
      ),
    );
  }
}
