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

GoRouter _buildRouter(WidgetRef ref) {
  final authNotifier = _AuthRefreshNotifier(ref);

  final shellKey = GlobalKey<NavigatorState>();
  final homeNavKey = GlobalKey<NavigatorState>();
  final inboxNavKey = GlobalKey<NavigatorState>();
  final activityNavKey = GlobalKey<NavigatorState>();
  final moreNavKey = GlobalKey<NavigatorState>();

  return GoRouter(
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
      GoRoute(
        path: '/review/:id',
        parentNavigatorKey: shellKey,
        builder: (_, state) =>
            ReviewScreen(transactionId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/manual-entry',
        parentNavigatorKey: shellKey,
        builder: (_, __) => const ManualEntryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: shellKey,
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home (Dashboard)
          StatefulShellBranch(
            navigatorKey: homeNavKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Inbox
          StatefulShellBranch(
            navigatorKey: inboxNavKey,
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (_, __) => const InboxScreen(),
              ),
            ],
          ),
          // Tab 2: Activity (Transactions)
          StatefulShellBranch(
            navigatorKey: activityNavKey,
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, __) => const TransactionsScreen(),
              ),
            ],
          ),
          // Tab 3: More (sub-routes preserve drawer compatibility for now)
          StatefulShellBranch(
            navigatorKey: moreNavKey,
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, __) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'budgets',
                    builder: (_, __) => const BudgetsScreen(),
                  ),
                  GoRoute(
                    path: 'goals',
                    builder: (_, __) => const GoalsScreen(),
                  ),
                  GoRoute(
                    path: 'accounts',
                    builder: (_, __) => const AccountsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, __) => const SettingsScreen(),
                  ),
                ],
              ),
              // Legacy top-level routes still resolve so existing drawer
              // links keep working without a screen-by-screen rewrite.
              GoRoute(
                path: '/budgets',
                builder: (_, __) => const BudgetsScreen(),
              ),
              GoRoute(
                path: '/goals',
                builder: (_, __) => const GoalsScreen(),
              ),
              GoRoute(
                path: '/accounts',
                builder: (_, __) => const AccountsScreen(),
              ),
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
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
