import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Dark-first Finance OS theme.
/// Light theme is provided as a near-mirror so the app can be installed on
/// devices that force light mode without falling back to default Material.
class AppTheme {
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final canvas = isDark ? AppColors.canvas : const Color(0xFFF7F8FA);
    final surface = isDark ? AppColors.surface : Colors.white;
    final surfaceElevated =
        isDark ? AppColors.surfaceElevated : const Color(0xFFF1F2F5);
    final border = isDark ? AppColors.border : const Color(0xFFE4E7EB);
    final borderStrong =
        isDark ? AppColors.borderStrong : const Color(0xFFD1D5DB);
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0B0F14);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF4B5563);
    final textMuted =
        isDark ? AppColors.textMuted : const Color(0xFF6B7280);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: AppColors.textOnAccent,
      primaryContainer: AppColors.accentDim,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.info,
      onSecondary: Colors.white,
      tertiary: AppColors.warning,
      onTertiary: Colors.black,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceElevated,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest:
          isDark ? AppColors.surfaceHigh : const Color(0xFFE9EBEF),
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: borderStrong,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.textPrimary : AppColors.canvas,
      onInverseSurface: isDark ? AppColors.canvas : AppColors.textPrimary,
      inversePrimary: AppColors.accentDim,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = _textTheme(textPrimary, textSecondary, textMuted);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.l,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        floatingLabelStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.accent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          disabledBackgroundColor: surfaceElevated,
          disabledForegroundColor: textMuted,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.l,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textOnAccent,
          ),
          elevation: 0,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: AppColors.accentSoft,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelLarge?.copyWith(color: textSecondary),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? const Color(0xFF6B7280) : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return surfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.accent,
        labelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        dividerColor: border,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accentSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.accent : textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accent : textSecondary,
            size: 24,
          );
        }),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xxl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: borderStrong,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
          side: BorderSide(color: border),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          side: BorderSide(color: border),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
      ),

      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppTheming.dark : _lightTheming,
      ],
    );
  }

  static TextTheme _textTheme(
    Color primary,
    Color secondary,
    Color muted,
  ) {
    // Tabular figures keep monetary columns vertically aligned everywhere.
    const numeric = <FontFeature>[FontFeature.tabularFigures()];

    // Body / UI face.
    TextStyle body(double size, FontWeight weight,
        {Color? color, double? height}) {
      return TextStyle(
        fontFamily: AppFonts.body,
        fontSize: size,
        fontWeight: weight,
        color: color ?? primary,
        height: height,
        letterSpacing: -0.1,
        fontFeatures: numeric,
      );
    }

    // Techy display face — used for headlines and large numeric figures.
    TextStyle display(double size, FontWeight weight,
        {Color? color, double? height}) {
      return TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        fontWeight: weight,
        color: color ?? primary,
        height: height,
        letterSpacing: -0.5,
        fontFeatures: numeric,
      );
    }

    return TextTheme(
      displayLarge: display(57, FontWeight.w700, height: 1.05),
      displayMedium: display(45, FontWeight.w700, height: 1.05),
      displaySmall: display(36, FontWeight.w700, height: 1.1),
      headlineLarge: display(32, FontWeight.w700, height: 1.15),
      headlineMedium: display(28, FontWeight.w600, height: 1.2),
      headlineSmall: display(24, FontWeight.w600, height: 1.25),
      titleLarge: body(20, FontWeight.w600, height: 1.3),
      titleMedium: body(16, FontWeight.w600, height: 1.4),
      titleSmall: body(14, FontWeight.w600, height: 1.4),
      bodyLarge: body(16, FontWeight.w400, height: 1.5),
      bodyMedium: body(14, FontWeight.w400, color: secondary, height: 1.5),
      bodySmall: body(12, FontWeight.w400, color: muted, height: 1.5),
      labelLarge: body(14, FontWeight.w500),
      labelMedium: body(12, FontWeight.w500, color: secondary),
      labelSmall: body(11, FontWeight.w500, color: muted),
    );
  }

  static const AppTheming _lightTheming = AppTheming(
    canvas: Color(0xFFF7F8FA),
    surface: Colors.white,
    surfaceElevated: Color(0xFFF1F2F5),
    border: Color(0xFFE4E7EB),
    borderStrong: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF0B0F14),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    success: AppColors.success,
    danger: AppColors.danger,
    warning: AppColors.warning,
    info: AppColors.info,
    skeletonBase: Color(0xFFE5E7EB),
    skeletonHighlight: Color(0xFFF3F4F6),
  );
}
