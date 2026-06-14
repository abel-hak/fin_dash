import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_transaction_app/data/db/database_helper.dart';
import 'package:sms_transaction_app/data/models/budget.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Seeds the local SQLite database with realistic sample data for UI preview.
/// Data is tagged with `demo_` prefixes so it can be cleared without touching
/// real user imports.
class DemoDataService {
  DemoDataService(this._db);

  final DatabaseHelper _db;

  static const _demoPrefix = 'demo_';

  /// Removes all demo-tagged rows, then inserts fresh sample data.
  /// Returns counts for user feedback.
  Future<({int transactions, int budgets, int goals})> seed() async {
    await clear();

    final txs = _sampleTransactions();
    for (final tx in txs) {
      await _db.insertParsedTransaction(tx);
    }

    for (final budget in _sampleBudgets()) {
      await _db.insertBudget(budget.toMap());
    }

    for (final goal in _sampleGoals()) {
      await _db.insertGoal(goal.toMap());
    }

    return (
      transactions: txs.length,
      budgets: _sampleBudgets().length,
      goals: _sampleGoals().length,
    );
  }

  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('parsed_tx', where: 'fingerprint LIKE ?', whereArgs: ['$_demoPrefix%']);
    await db.delete('budgets', where: 'id LIKE ?', whereArgs: ['$_demoPrefix%']);
    await db.delete('goals', where: 'id LIKE ?', whereArgs: ['$_demoPrefix%']);
  }

  List<ParsedTransaction> _sampleTransactions() {
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    ParsedTransaction tx({
      required String suffix,
      required String sender,
      required double amount,
      required String merchant,
      required DateTime when,
      required TransactionStatus status,
      double? balance,
      String? reason,
      String channel = 'sms',
      String? recipient,
      String? accountAlias,
    }) {
      final id = '$_demoPrefix$suffix';
      return ParsedTransaction(
        id: id,
        sender: sender,
        amount: amount,
        currency: 'ETB',
        occurredAt: iso(when),
        merchant: merchant,
        accountAlias: accountAlias ?? '****8193',
        balance: balance,
        channel: channel,
        confidence: 0.94,
        fingerprint: '$_demoPrefix$suffix',
        status: status,
        createdAt: iso(when),
        transactionId: 'TX${suffix.toUpperCase()}',
        recipient: recipient,
        reason: reason,
        dataSource: 'sms',
      );
    }

    return [
      // --- Pending (Inbox tab) ---
      tx(
        suffix: 'tx_pending_01',
        sender: 'Telebirr',
        amount: 350,
        merchant: 'Ethio Telecom',
        reason: 'Mobile Data Bundle',
        when: daysAgo(0),
        status: TransactionStatus.pending,
        balance: 12450.75,
        channel: 'telebirr',
      ),
      tx(
        suffix: 'tx_pending_02',
        sender: 'CBE',
        amount: 2800,
        merchant: 'Kidus Yared',
        reason: 'Fund transfer',
        when: daysAgo(0),
        status: TransactionStatus.pending,
        balance: 12100.75,
        recipient: 'Kidus Yared',
      ),
      tx(
        suffix: 'tx_pending_03',
        sender: 'Awash Bank',
        amount: 890,
        merchant: 'Sheger Cafe',
        reason: 'Restaurant lunch',
        when: daysAgo(1),
        status: TransactionStatus.pending,
        balance: 5200,
        accountAlias: '****4521',
      ),

      // --- Approved (awaiting sync) ---
      tx(
        suffix: 'tx_approved_01',
        sender: 'CBE',
        amount: 450,
        merchant: 'Tomoca Coffee',
        reason: 'Coffee shop',
        when: daysAgo(1),
        status: TransactionStatus.approved,
        balance: 14900.75,
      ),
      tx(
        suffix: 'tx_approved_02',
        sender: 'Telebirr',
        amount: 120,
        merchant: 'Ride Addis',
        reason: 'Taxi ride',
        when: daysAgo(2),
        status: TransactionStatus.approved,
        balance: 15350.75,
        channel: 'telebirr',
      ),
      tx(
        suffix: 'tx_approved_03',
        sender: 'CBE',
        amount: 3200,
        merchant: 'Bole Medhanialem Mall',
        reason: 'Shopping purchase',
        when: daysAgo(3),
        status: TransactionStatus.approved,
        balance: 15470.75,
      ),

      // --- Synced (Activity / Dashboard) ---
      tx(
        suffix: 'tx_sync_01',
        sender: 'CBE',
        amount: 15000,
        merchant: 'Employer Salary Deposit',
        reason: 'Monthly salary income',
        when: daysAgo(4),
        status: TransactionStatus.synced,
        balance: 18670.75,
      ),
      tx(
        suffix: 'tx_sync_02',
        sender: 'CBE',
        amount: 850,
        merchant: 'Kategna Restaurant',
        reason: 'Restaurant dinner',
        when: daysAgo(5),
        status: TransactionStatus.synced,
        balance: 3670.75,
      ),
      tx(
        suffix: 'tx_sync_03',
        sender: 'Telebirr',
        amount: 180,
        merchant: 'Bolt Ride',
        reason: 'Taxi transport',
        when: daysAgo(5),
        status: TransactionStatus.synced,
        balance: 4520.75,
        channel: 'telebirr',
      ),
      tx(
        suffix: 'tx_sync_04',
        sender: 'CBE',
        amount: 2200,
        merchant: 'Safeway Supermarket',
        reason: 'Grocery shopping',
        when: daysAgo(6),
        status: TransactionStatus.synced,
        balance: 4700.75,
      ),
      tx(
        suffix: 'tx_sync_05',
        sender: 'Telebirr',
        amount: 650,
        merchant: 'Ethio Telecom',
        reason: 'Internet bill payment',
        when: daysAgo(7),
        status: TransactionStatus.synced,
        balance: 6900.75,
        channel: 'telebirr',
      ),
      tx(
        suffix: 'tx_sync_06',
        sender: 'CBE',
        amount: 4200,
        merchant: 'Zemen Bank Transfer',
        reason: 'Fund transfer',
        when: daysAgo(8),
        status: TransactionStatus.synced,
        balance: 7550.75,
        recipient: 'Sara Bekele',
      ),
      tx(
        suffix: 'tx_sync_07',
        sender: 'Telebirr',
        amount: 299,
        merchant: 'Netflix Subscription',
        reason: 'Entertainment subscription',
        when: daysAgo(9),
        status: TransactionStatus.synced,
        balance: 11750.75,
        channel: 'telebirr',
      ),
      tx(
        suffix: 'tx_sync_08',
        sender: 'CBE',
        amount: 1500,
        merchant: 'Bole Cinema',
        reason: 'Movie entertainment',
        when: daysAgo(10),
        status: TransactionStatus.synced,
        balance: 12049.75,
      ),
      tx(
        suffix: 'tx_sync_09',
        sender: 'Awash Bank',
        amount: 3400,
        merchant: 'H&M Store',
        reason: 'Clothing shopping',
        when: daysAgo(11),
        status: TransactionStatus.synced,
        balance: 13549.75,
        accountAlias: '****4521',
      ),
      tx(
        suffix: 'tx_sync_10',
        sender: 'CBE',
        amount: 980,
        merchant: 'Total Gas Station',
        reason: 'Fuel purchase',
        when: daysAgo(12),
        status: TransactionStatus.synced,
        balance: 16949.75,
      ),
      tx(
        suffix: 'tx_sync_11',
        sender: 'Telebirr',
        amount: 2500,
        merchant: 'Ride Addis',
        reason: 'Transport weekly pass',
        when: daysAgo(13),
        status: TransactionStatus.synced,
        balance: 17929.75,
        channel: 'telebirr',
      ),
      tx(
        suffix: 'tx_sync_12',
        sender: 'CBE',
        amount: 5000,
        merchant: 'Freelance Client Deposit',
        reason: 'Income deposit',
        when: daysAgo(18),
        status: TransactionStatus.synced,
        balance: 20429.75,
      ),
      tx(
        suffix: 'tx_sync_13',
        sender: 'CBE',
        amount: 720,
        merchant: 'Lucy Hospital',
        reason: 'Pharmacy medicine',
        when: daysAgo(20),
        status: TransactionStatus.synced,
        balance: 15429.75,
      ),
      tx(
        suffix: 'tx_sync_14',
        sender: 'Telebirr',
        amount: 1100,
        merchant: 'Mini Mart Bole',
        reason: 'Food grocery',
        when: daysAgo(22),
        status: TransactionStatus.synced,
        balance: 16149.75,
        channel: 'telebirr',
      ),

      // --- Ignored (hidden from main flows) ---
      tx(
        suffix: 'tx_ignored_01',
        sender: 'CBE',
        amount: 50,
        merchant: 'SMS Alert Fee',
        when: daysAgo(25),
        status: TransactionStatus.ignored,
        balance: 16249.75,
      ),
    ];
  }

  List<Budget> _sampleBudgets() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    Budget b(String suffix, String name, String category, double limit) {
      return Budget(
        id: '$_demoPrefix$suffix',
        name: name,
        category: category,
        limit: limit,
        spent: 0,
        period: 'monthly',
        startDate: start,
        endDate: end,
        isActive: true,
      );
    }

    return [
      b('budget_food', 'Food & Dining', 'Food & Dining', 8000),
      b('budget_transport', 'Transportation', 'Transportation', 4000),
      b('budget_entertainment', 'Entertainment', 'Entertainment', 3000),
      b('budget_utilities', 'Utilities', 'Utilities', 2000),
      b('budget_shopping', 'Shopping', 'Shopping', 10000),
    ];
  }

  List<Goal> _sampleGoals() {
    final now = DateTime.now();

    Goal g(
      String suffix,
      String name,
      String description,
      double target,
      double current,
      int monthsOut,
      String icon,
    ) {
      return Goal(
        id: '$_demoPrefix$suffix',
        name: name,
        description: description,
        targetAmount: target,
        currentAmount: current,
        deadline: DateTime(now.year, now.month + monthsOut, now.day),
        iconName: icon,
        isActive: true,
      );
    }

    return [
      g(
        'goal_emergency',
        'Emergency Fund',
        'Six months of living expenses',
        50000,
        32500,
        8,
        'savings',
      ),
      g(
        'goal_laptop',
        'New Laptop',
        'MacBook for development work',
        85000,
        12000,
        10,
        'laptop',
      ),
      g(
        'goal_vacation',
        'Zanzibar Trip',
        'Beach vacation with friends',
        25000,
        22000,
        3,
        'flight',
      ),
      g(
        'goal_phone',
        'Phone Upgrade',
        'Replace aging device',
        35000,
        35000,
        1,
        'phone',
      ),
    ];
  }
}

final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  return DemoDataService(ref.watch(databaseHelperProvider));
});

/// Invalidates all providers that read demo-seeded data.
void invalidateDemoDataProviders(WidgetRef ref) {
  ref.invalidate(parsedTransactionsProvider);
  ref.invalidate(pendingTransactionsProvider);
  ref.invalidate(approvedTransactionsProvider);
  ref.invalidate(syncedTransactionsProvider);
  ref.invalidate(budgetsProvider);
  ref.invalidate(goalsProvider);
  ref.invalidate(accountsProvider);
  ref.read(transactionRefreshProvider.notifier).state++;
}
