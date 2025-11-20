import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sms_transaction_app/features/auth/login_screen.dart';
import 'package:sms_transaction_app/features/auth/register_screen.dart';
import 'package:sms_transaction_app/features/auth/consent_screen.dart';
import 'package:sms_transaction_app/features/dashboard/dashboard_screen.dart';
import 'package:sms_transaction_app/features/accounts/accounts_screen.dart';
import 'package:sms_transaction_app/features/transactions/transactions_screen.dart';
import 'package:sms_transaction_app/features/budgets/budgets_screen.dart';
import 'package:sms_transaction_app/features/goals/goals_screen.dart';
import 'package:sms_transaction_app/features/inbox/inbox_screen.dart';
import 'package:sms_transaction_app/features/inbox/manual_entry_screen.dart';
import 'package:sms_transaction_app/features/review/review_screen.dart';
import 'package:sms_transaction_app/features/settings/settings_screen.dart';
import 'package:sms_transaction_app/services/providers.dart';
import 'package:sms_transaction_app/core/theme.dart';
import 'package:sms_transaction_app/core/env_config.dart';
import 'package:sms_transaction_app/core/logger.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/domain/parser/ai_sms_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final dbHelper = DatabaseHelper();
  // Note: Only reset database during development if needed
  // await dbHelper.resetDatabase(); // Uncomment only for schema changes
  await dbHelper.database; // Initialize the database

  // Initialize Supabase with environment configuration
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  // Initialize AI parser (Gemini)
  AiSmsParser.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize SMS service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSmsService();
    });
  }

  Future<void> _initializeSmsService() async {
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
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (BuildContext context, GoRouterState state) {
        final isLoggedIn = ref
            .watch(authStateProvider)
            .maybeWhen(
              data: (authState) => authState.session != null,
              orElse: () => false,
            );

        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        } else if (isLoggedIn && isAuthRoute) {
          return '/dashboard';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterScreen(),
        ),
        GoRoute(
          path: '/consent',
          builder: (BuildContext context, GoRouterState state) =>
              const ConsentScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardScreen(),
        ),
        GoRoute(
          path: '/accounts',
          builder: (BuildContext context, GoRouterState state) =>
              const AccountsScreen(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (BuildContext context, GoRouterState state) =>
              const TransactionsScreen(),
        ),
        GoRoute(
          path: '/budgets',
          builder: (BuildContext context, GoRouterState state) =>
              const BudgetsScreen(),
        ),
        GoRoute(
          path: '/goals',
          builder: (BuildContext context, GoRouterState state) =>
              const GoalsScreen(),
        ),
        GoRoute(
          path: '/inbox',
          builder: (BuildContext context, GoRouterState state) =>
              const InboxScreen(),
        ),
        GoRoute(
          path: '/manual-entry',
          builder: (BuildContext context, GoRouterState state) =>
              const ManualEntryScreen(),
        ),
        GoRoute(
          path: '/review/:id',
          builder: (BuildContext context, GoRouterState state) =>
              ReviewScreen(transactionId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) =>
              const SettingsScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'SMS Transaction App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
