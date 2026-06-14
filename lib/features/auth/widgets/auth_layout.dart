import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_transaction_app/core/tokens.dart';

/// Shared dark-first shell for login / register flows.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.theming;

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.accentGradient,
            ),
            borderRadius: BorderRadius.circular(AppRadii.l),
            boxShadow: AppShadows.glow(),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.textOnAccent,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Finance OS',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Track your transactions automatically',
          style: theme.textTheme.bodyMedium?.copyWith(color: t.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Full-width Login / Sign Up pill toggle.
class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// 0 = Login, 1 = Sign Up
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _labels = ['Login', 'Sign Up'];

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
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (i == selectedIndex) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  decoration: BoxDecoration(
                    color:
                        i == selectedIndex ? AppColors.lime : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: i == selectedIndex
                          ? AppColors.textOnAccent
                          : t.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class AuthPrivacyFooter extends StatelessWidget {
  const AuthPrivacyFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.theming;

    return Text(
      'SMS data stays on your device. We only store approved transactions.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textMuted),
      textAlign: TextAlign.center,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Primary CTA with brand gradient fill.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : const LinearGradient(colors: AppColors.accentGradient),
        color: disabled ? context.theming.surfaceElevated : null,
        borderRadius: BorderRadius.circular(AppRadii.m),
        boxShadow: disabled ? null : AppShadows.glow(),
      ),
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnAccent,
                ),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: disabled
                          ? context.theming.textMuted
                          : AppColors.textOnAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
      ),
    );
  }
}

/// Navigates between login and register when the mode toggle changes.
void authModeNavigate(BuildContext context, int index) {
  if (index == 0) {
    context.go('/login');
  } else {
    context.go('/register');
  }
}
