import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sms_transaction_app/core/env_config.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/core/theme.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/domain/parser/ai_sms_parser.dart';
import 'package:sms_transaction_app/features/accounts/accounts_screen.dart';
import 'package:sms_transaction_app/features/auth/consent_screen.dart';
import 'package:sms_transaction_app/features/auth/login_screen.dart';
import 'package:sms_transaction_app/features/auth/register_screen.dart';
import 'package:sms_transaction_app/features/budgets/budgets_screen.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_screen.dart';
import 'package:sms_transaction_app/features/goals/goals_screen.dart';
import 'package:sms_transaction_app/features/inbox/inbox_screen.dart';
import 'package:sms_transaction_app/features/inbox/manual_entry_screen.dart';
import 'package:sms_transaction_app/features/review/review_screen.dart';
import 'package:sms_transaction_app/features/settings/settings_screen.dart';
import 'package:sms_transaction_app/features/shell/app_shell.dart';
import 'package:sms_transaction_app/features/shell/more_screen.dart';
import 'package:sms_transaction_app/features/transactions/transactions_screen.dart';
import 'package:sms_transaction_app/services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate env config (throws in release if Supabase secrets are missing).
  EnvConfig.validate();

  // Initialize the local DB before runApp so the providers can assume it's
  // ready. The DatabaseHelper itself is a singleton, so this is the same
  // instance the providers will get.
  await DatabaseHelper().database;

  if (EnvConfig.hasSupabase) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  } else {
    AppLogger.warning(
      'Supabase not initialized: missing env config. Auth/sync are disabled.',
    );
  }

  AiSmsParser.initialize();

  runApp(const ProviderScope(child: SmsTransactionApp()));
}

class SmsTransactionApp extends ConsumerStatefulWidget {
  const SmsTransactionApp({super.key});

  @override
  ConsumerState<SmsTransactionApp> createState() => _SmsTransactionAppState();
}

class _SmsTransactionAppState extends ConsumerState<SmsTransactionApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(ref);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    // Subscribe sync lifecycle to auth state.
    ref.read(syncLifecycleProvider);
    // Initialize SMS service after templates load.
    try {
      await ref.read(templateRegistryProvider.future);
      final smsService = ref.read(smsServiceProvider);
      await smsService.initialize();
      AppLogger.info('SMS service started successfully');
    } catch (e, stackTrace) {
      AppLogger.error('SMS service initialization failed', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SMS Transaction App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) {
        // Force the system status-bar icons to match the dark theme.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

// Root navigator key — passed to GoRouter and used as parentNavigatorKey for
// routes that must render above the bottom-nav shell (review, manual-entry).
final _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter _buildRouter(WidgetRef ref) {
  final authNotifier = _AuthRefreshNotifier(ref);

  final homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  final inboxNavKey = GlobalKey<NavigatorState>(debugLabel: 'inbox');
  final activityNavKey = GlobalKey<NavigatorState>(debugLabel: 'activity');
  final moreNavKey = GlobalKey<NavigatorState>(debugLabel: 'more');

  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = ref.read(authStateProvider).maybeWhen(
            data: (authState) => authState.session != null,
            orElse: () => false,
          );
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/consent';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && (loc == '/login' || loc == '/register')) {
        return '/dashboard';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (_, __) => const ConsentScreen(),
      ),
      // These routes use _rootNavKey so they render full-screen above the
      // bottom-nav shell — the shell's bottom bar disappears while on them.
      GoRoute(
        path: '/review/:id',
        parentNavigatorKey: _rootNavKey,
        builder: (_, state) =>
            ReviewScreen(transactionId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/manual-entry',
        parentNavigatorKey: _rootNavKey,
        builder: (_, __) => const ManualEntryScreen(),
      ),
      // Legacy top-level paths → nested under /more (keeps shell branch stable).
      GoRoute(
        path: '/budgets',
        redirect: (_, __) => '/more/budgets',
      ),
      GoRoute(
        path: '/goals',
        redirect: (_, __) => '/more/goals',
      ),
      GoRoute(
        path: '/accounts',
        redirect: (_, __) => '/more/accounts',
      ),
      GoRoute(
        path: '/settings',
        redirect: (_, __) => '/more/settings',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home (Dashboard)
          StatefulShellBranch(
            navigatorKey: homeNavKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          // Tab 1: Inbox
          StatefulShellBranch(
            navigatorKey: inboxNavKey,
            routes: [
              GoRoute(
                path: '/inbox',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const InboxScreen(),
                ),
              ),
            ],
          ),
          // Tab 2: Activity (Transactions)
          StatefulShellBranch(
            navigatorKey: activityNavKey,
            routes: [
              GoRoute(
                path: '/transactions',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const TransactionsScreen(),
                ),
              ),
            ],
          ),
          // Tab 3: More — budget/goals/accounts/settings as sub-routes plus
          // legacy top-level paths so existing `context.go('/budgets')` calls
          // keep working without a screen-by-screen rewrite.
          StatefulShellBranch(
            navigatorKey: moreNavKey,
            routes: [
              GoRoute(
                path: '/more',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const MoreScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'budgets',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const BudgetsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'goals',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const GoalsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'accounts',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const AccountsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'settings',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const SettingsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridges the Riverpod auth state stream to GoRouter's `refreshListenable`
/// so route redirects re-evaluate when the user signs in or out.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(WidgetRef ref) {
    _sub = ref.listenManual(authStateProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
