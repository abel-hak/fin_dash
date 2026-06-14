import 'package:flutter/material.dart';

/// Design tokens for the dark-first Finance OS visual language.
/// All UI should consume these instead of hardcoded values.
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

class AppRadii {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

/// Font families bundled in `pubspec.yaml`. `body` is the default UI face;
/// `display` is the techy face used for headlines and large numeric figures.
class AppFonts {
  static const String body = 'Inter';
  static const String display = 'Space Grotesk';
}

/// Elevation + brand-glow shadows. Consume via `AppShadows.glow()` etc. rather
/// than hand-rolling `BoxShadow`s in feature code.
class AppShadows {
  /// Soft ambient lift for elevated cards on the dark canvas.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  /// Brand glow for the balance hero / primary CTAs. Pass the leading accent
  /// color (defaults to emerald).
  static List<BoxShadow> glow([Color color = AppColors.accent]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 32,
          spreadRadius: -8,
          offset: const Offset(0, 12),
        ),
      ];
}

class AppMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 340);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve spring = Curves.elasticOut;
}

/// Single source of truth for the dark Finance OS palette.
/// Avoid using `Colors.*` constants directly in features — pull from here
/// (or, preferably, `Theme.of(context).colorScheme`).
class AppColors {
  // Canvas / surfaces
  static const Color canvas = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF14191F);
  static const Color surfaceElevated = Color(0xFF1B2128);
  static const Color surfaceHigh = Color(0xFF222A33);
  static const Color border = Color(0xFF232A33);
  static const Color borderStrong = Color(0xFF2C3540);
  static const Color overlay = Color(0xCC000000);

  // Text
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textOnAccent = Color(0xFF00150A);

  // Brand / accent (emerald base + lime highlight)
  static const Color accent = Color(0xFF00D26A);
  static const Color accentDim = Color(0xFF008F47);
  static const Color accentSoft = Color(0x3300D26A);

  /// Bright lime highlight — used for the active pill, donut emphasis and the
  /// far end of the brand gradient (the "pop" in the reference).
  static const Color lime = Color(0xFFB6FF3C);
  static const Color limeSoft = Color(0x33B6FF3C);

  /// Secondary chart hue (cool indigo/blue) for multi-series breakdowns.
  static const Color violet = Color(0xFF6C5CE7);

  /// Brand gradient (emerald → lime). Used on the balance hero and CTAs.
  static const List<Color> accentGradient = [Color(0xFF00D26A), Color(0xFFB6FF3C)];

  /// Palette used to color category slices in the breakdown donut.
  static const List<Color> categoryPalette = [
    Color(0xFFB6FF3C), // lime
    Color(0xFF00D26A), // emerald
    Color(0xFF4DA8FF), // info blue
    Color(0xFF6C5CE7), // violet
    Color(0xFFFFB454), // warning amber
    Color(0xFFFF5C7A), // danger rose
  ];

  // Semantic
  static const Color success = Color(0xFF00D26A);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color dangerSoft = Color(0x33FF5C7A);
  static const Color warning = Color(0xFFFFB454);
  static const Color warningSoft = Color(0x33FFB454);
  static const Color info = Color(0xFF4DA8FF);
  static const Color infoSoft = Color(0x334DA8FF);

  // Skeleton / shimmer
  static const Color skeletonBase = Color(0xFF1B2128);
  static const Color skeletonHighlight = Color(0xFF252D38);
}

/// Icon + color for a spending category. Pair with
/// `Budget.getCategoryFromMerchant`, which produces the canonical category
/// names this maps. Centralizes the icon/color choices that used to be
/// hand-rolled inside individual screens.
@immutable
class CategoryVisual {
  const CategoryVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

class CategoryVisuals {
  const CategoryVisuals._();

  static const Map<String, CategoryVisual> _byName = {
    'Transfer': CategoryVisual(Icons.swap_horiz, AppColors.violet),
    'Utilities': CategoryVisual(Icons.flash_on, AppColors.warning),
    'Food & Dining': CategoryVisual(Icons.restaurant, Color(0xFFFFB454)),
    'Transportation': CategoryVisual(Icons.directions_car, AppColors.info),
    'Shopping': CategoryVisual(Icons.shopping_bag, AppColors.violet),
    'Entertainment': CategoryVisual(Icons.movie, AppColors.accent),
    'Healthcare': CategoryVisual(Icons.local_hospital, AppColors.danger),
    'Income': CategoryVisual(Icons.arrow_downward, AppColors.success),
  };

  static const CategoryVisual _fallback =
      CategoryVisual(Icons.receipt, AppColors.info);

  /// Look up the visual for a canonical category name. Unknown names fall back
  /// to a neutral receipt icon.
  static CategoryVisual forName(String category) =>
      _byName[category] ?? _fallback;
}

/// Theme extension exposing tokens that don't fit neatly in `ColorScheme`.
/// Read via `Theme.of(context).extension<AppTheming>()!`.
@immutable
class AppTheming extends ThemeExtension<AppTheming> {
  const AppTheming({
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const AppTheming dark = AppTheming(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    success: AppColors.success,
    danger: AppColors.danger,
    warning: AppColors.warning,
    info: AppColors.info,
    skeletonBase: AppColors.skeletonBase,
    skeletonHighlight: AppColors.skeletonHighlight,
  );

  @override
  AppTheming copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppTheming(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppTheming lerp(ThemeExtension<AppTheming>? other, double t) {
    if (other is! AppTheming) return this;
    return AppTheming(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight:
          Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}

/// Convenience accessor: `context.theming.surface`
extension AppThemingX on BuildContext {
  AppTheming get theming =>
      Theme.of(this).extension<AppTheming>() ?? AppTheming.dark;
}
