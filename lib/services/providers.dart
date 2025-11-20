import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sms_transaction_app/core/env_config.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/data/models/account.dart';
import 'package:sms_transaction_app/data/models/budget.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/domain/parser/sms_parser.dart';
import 'package:sms_transaction_app/domain/templates/template_model.dart';
import 'package:sms_transaction_app/services/auth_service.dart';
import 'package:sms_transaction_app/services/permissions_service.dart';
import 'package:sms_transaction_app/services/preferences_service.dart';
import 'package:sms_transaction_app/services/sms_service.dart';
import 'package:sms_transaction_app/services/sync_service.dart';
import 'package:sms_transaction_app/services/template_service.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Database helper provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthService(
    supabaseClient: supabaseClient,
    secureStorage: secureStorage,
  );
});

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return supabaseClient.auth.onAuthStateChange;
});

// User provider
final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user).value;
});

// Template service provider
final templateServiceProvider = Provider<TemplateService>((ref) {
  return TemplateService();
});

// Template registry provider
final templateRegistryProvider = FutureProvider<TemplateRegistry>((ref) async {
  final templateService = ref.watch(templateServiceProvider);
  return await templateService.getTemplates();
});

// SMS parser provider
final smsParserProvider = Provider<SmsParser>((ref) {
  final templateRegistry = ref.watch(templateRegistryProvider).value;
  if (templateRegistry == null) {
    throw Exception('Template registry not loaded');
  }
  return SmsParser(templateRegistry);
});

// Permissions service provider
final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  return PermissionsService();
});

// SMS permission state provider
final smsPermissionProvider = FutureProvider<bool>((ref) async {
  final permissionsService = ref.watch(permissionsServiceProvider);
  return await permissionsService.checkSmsPermission();
});

// Preferences service provider
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

// Trusted senders provider
final trustedSendersProvider = FutureProvider<List<String>>((ref) async {
  final preferencesService = ref.watch(preferencesServiceProvider);
  return await preferencesService.getTrustedSenders();
});

// Auto-approve settings provider
final autoApproveSettingsProvider = FutureProvider<Map<String, bool>>((
  ref,
) async {
  final preferencesService = ref.watch(preferencesServiceProvider);
  return await preferencesService.getAutoApproveSettings();
});

// Delete raw setting provider
final deleteRawSettingProvider = FutureProvider<bool>((ref) async {
  final preferencesService = ref.watch(preferencesServiceProvider);
  return await preferencesService.getDeleteRawSetting();
});

// SMS service provider
final smsServiceProvider = Provider<SmsService>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final smsParser = ref.watch(smsParserProvider);
  final authService = ref.watch(authServiceProvider);
  final templateService = ref.watch(templateServiceProvider);

  return SmsService(
    databaseHelper: databaseHelper,
    smsParser: smsParser,
    authService: authService,
    templateService: templateService,
  );
});

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final authService = ref.watch(authServiceProvider);

  return SyncService(
    databaseHelper: databaseHelper,
    apiUrl: '${EnvConfig.apiUrl}/transactions',
    getAuthToken: () {
      // Note: This is a synchronous wrapper for the async getAuthToken
      // In a real app, you might want to cache the token or use a different approach
      return authService.getCurrentToken() ?? '';
    },
  );
});

// Refresh trigger for transactions
final transactionRefreshProvider = StateProvider<int>((ref) => 0);

// Parsed transactions provider
final parsedTransactionsProvider = FutureProvider<List<ParsedTransaction>>((
  ref,
) async {
  // Watch the refresh trigger to invalidate when needed
  ref.watch(transactionRefreshProvider);
  final databaseHelper = ref.watch(databaseHelperProvider);
  return await databaseHelper.getParsedTransactions();
});

// Pending transactions provider
final pendingTransactionsProvider = FutureProvider<List<ParsedTransaction>>((
  ref,
) async {
  // Watch the refresh trigger to invalidate when needed
  ref.watch(transactionRefreshProvider);
  final databaseHelper = ref.watch(databaseHelperProvider);
  return await databaseHelper.getParsedTransactions(
    status: TransactionStatus.pending,
  );
});

// Approved transactions provider
final approvedTransactionsProvider = FutureProvider<List<ParsedTransaction>>((
  ref,
) async {
  // Watch the refresh trigger to invalidate when needed
  ref.watch(transactionRefreshProvider);
  final databaseHelper = ref.watch(databaseHelperProvider);
  return await databaseHelper.getParsedTransactions(
    status: TransactionStatus.approved,
  );
});

// Synced transactions provider
final syncedTransactionsProvider = FutureProvider<List<ParsedTransaction>>((
  ref,
) async {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return await databaseHelper.getParsedTransactions(
    status: TransactionStatus.synced,
  );
});

// Accounts provider - generates accounts from transactions
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final transactions = await ref.watch(parsedTransactionsProvider.future);
  
  if (transactions.isEmpty) {
    return [];
  }
  
  // Group transactions by sender
  final accountData = <String, Map<String, dynamic>>{};
  
  for (var tx in transactions) {
    if (!accountData.containsKey(tx.sender)) {
      accountData[tx.sender] = {
        'balance': tx.balance ?? 0.0,
        'count': 0,
        'lastDate': DateTime.parse(tx.occurredAt),
      };
    }
    
    accountData[tx.sender]!['count'] = (accountData[tx.sender]!['count'] as int) + 1;
    
    // Update balance if this transaction is more recent
    final txDate = DateTime.parse(tx.occurredAt);
    if (txDate.isAfter(accountData[tx.sender]!['lastDate'] as DateTime)) {
      accountData[tx.sender]!['balance'] = tx.balance ?? 0.0;
      accountData[tx.sender]!['lastDate'] = txDate;
    }
  }
  
  // Convert to Account objects
  final accounts = accountData.entries.map((entry) {
    return Account.fromTransactions(
      sender: entry.key,
      balance: entry.value['balance'] as double,
      transactionCount: entry.value['count'] as int,
      lastSynced: entry.value['lastDate'] as DateTime,
    );
  }).toList();
  
  // Sort by balance descending
  accounts.sort((a, b) => b.balance.compareTo(a.balance));
  
  return accounts;
});

// Budgets provider - reads from database and calculates spending
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final db = ref.watch(databaseHelperProvider);
  final transactions = await ref.watch(parsedTransactionsProvider.future);
  
  // Get budgets from database
  final budgetMaps = await db.getBudgets(isActive: true);
  
  if (budgetMaps.isEmpty) {
    return [];
  }
  
  // Get current month date range
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  
  // Filter transactions for current month (exclude income)
  final monthTransactions = transactions.where((tx) {
    try {
      final txDate = DateTime.parse(tx.occurredAt);
      final isInMonth = txDate.isAfter(monthStart.subtract(const Duration(days: 1))) && 
                        txDate.isBefore(monthEnd.add(const Duration(days: 1)));
      final isExpense = !tx.merchant.toLowerCase().contains('salary') &&
                        !tx.merchant.toLowerCase().contains('income') &&
                        !tx.merchant.toLowerCase().contains('deposit');
      return isInMonth && isExpense;
    } catch (e) {
      return false;
    }
  }).toList();
  
  // Group spending by category
  final categorySpending = <String, double>{};
  for (var tx in monthTransactions) {
    final category = Budget.getCategoryFromMerchant(tx.merchant, reason: tx.reason);
    categorySpending[category] = (categorySpending[category] ?? 0) + tx.amount;
  }
  
  // Create budget objects from database with calculated spending
  final budgets = budgetMaps.map((map) {
    final category = map['category'] as String;
    final spent = categorySpending[category] ?? 0.0;
    return Budget.fromMap(map, spent);
  }).toList();
  
  // Sort by percentage used (highest first)
  budgets.sort((a, b) => b.percentage.compareTo(a.percentage));
  
  return budgets;
});

// Goals provider - reads from database
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final db = ref.watch(databaseHelperProvider);
  
  // Get goals from database
  final goalMaps = await db.getGoals(isActive: true);
  
  if (goalMaps.isEmpty) {
    return [];
  }
  
  // Create goal objects from database
  final goals = goalMaps.map((map) => Goal.fromMap(map)).toList();
  
  // Sort by percentage complete (highest first)
  goals.sort((a, b) => b.percentage.compareTo(a.percentage));
  
  return goals;
});
