import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav branch indices — must match [StatefulShellRoute] order in main.dart.
abstract final class ShellTab {
  static const home = 0;
  static const inbox = 1;
  static const activity = 2;
  static const more = 3;
}

extension ShellNavigation on BuildContext {
  /// Current path without using [GoRouterState.of], which can assert inside
  /// nested shell branch navigators.
  String get shellLocation =>
      GoRouter.of(this).routerDelegate.currentConfiguration.uri.path;

  bool isShellRouteSelected(String route) {
    final current = shellLocation;
    if (current == route) return true;
    // Supports nested more routes such as /more/goals when route is /goals.
    return current.endsWith(route);
  }

  /// Navigate from the drawer or other in-shell surfaces without corrupting the
  /// indexed stack page registry.
  void goShellRoute(String route) {
    final shell = StatefulNavigationShell.maybeOf(this);
    final tabIndex = _tabIndexForRoute(route);

    if (shell != null && tabIndex != null) {
      final onSameTab = shell.currentIndex == tabIndex;
      shell.goBranch(
        tabIndex,
        initialLocation: onSameTab && route != '/more',
      );
    }

    if (route != '/more' || shell == null) {
      go(route);
    } else if (shell.currentIndex == ShellTab.more) {
      go('/more');
    }
  }

  int? _tabIndexForRoute(String route) {
    return switch (route) {
      '/dashboard' => ShellTab.home,
      '/inbox' => ShellTab.inbox,
      '/transactions' => ShellTab.activity,
      '/more' ||
      '/budgets' ||
      '/goals' ||
      '/accounts' ||
      '/settings' =>
        ShellTab.more,
      _ => null,
    };
  }
}
