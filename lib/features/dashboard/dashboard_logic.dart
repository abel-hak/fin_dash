import 'package:sms_transaction_app/core/widgets/charts.dart';
import 'package:sms_transaction_app/data/models/budget.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';
import 'package:sms_transaction_app/domain/transaction_rules.dart';

/// Visual tone for a generated insight. Mapped to icon + color in the widget
/// layer so this stays Flutter-free and unit-testable.
enum InsightTone { positive, warning, danger, neutral }

/// A single derived insight shown in the dashboard "AI Insights" card.
class DashboardInsight {
  const DashboardInsight({
    required this.tone,
    required this.title,
    required this.message,
  });

  final InsightTone tone;
  final String title;
  final String message;
}

/// Shared, pure helpers for deriving dashboard view-data from the raw parsed
/// transaction list. Kept separate from widgets so the income/category
/// heuristics live in one place (they mirror the logic in `budgetsProvider`).
class DashboardData {
  const DashboardData._();

  /// Heuristic: a transaction is income if its merchant looks like a salary /
  /// deposit. Delegates to the shared [TransactionRules] so dashboard, budgets,
  /// and the transactions list all classify identically.
  static bool isIncome(ParsedTransaction tx) => TransactionRules.isIncome(tx);

  /// Most recent known balance (transactions are stored newest-first).
  static double latestBalance(List<ParsedTransaction> txs) {
    for (final tx in txs) {
      if (tx.balance != null) return tx.balance!;
    }
    return 0;
  }

  /// Balance values ordered oldest → newest, capped at [maxPoints] for a clean
  /// sparkline. Empty when fewer than two balances are known.
  static List<double> balanceHistory(
    List<ParsedTransaction> txs, {
    int maxPoints = 24,
  }) {
    final withBalance = txs.where((tx) => tx.balance != null).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final values = withBalance.map((tx) => tx.balance!).toList();
    if (values.length <= maxPoints) return values;
    return values.sublist(values.length - maxPoints);
  }

  /// Month-over-month change in balance, as a display label like
  /// `'+2.4% this month'`. Compares the latest known balance against the most
  /// recent balance recorded *before* the start of the current month. Returns
  /// null when there isn't enough history (or the baseline is zero) to compute
  /// a meaningful percentage — callers should hide the delta in that case.
  static String? balanceDeltaLabel(List<ParsedTransaction> txs) {
    final withBalance = txs.where((tx) => tx.balance != null).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    if (withBalance.length < 2) return null;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final current = withBalance.last.balance!;

    // Latest balance dated before this month — the baseline we grew from.
    double? baseline;
    for (final tx in withBalance) {
      final date = DateTime.tryParse(tx.occurredAt);
      if (date == null) continue;
      if (date.isBefore(monthStart)) {
        baseline = tx.balance;
      } else {
        break;
      }
    }

    if (baseline == null || baseline == 0) return null;

    final pct = (current - baseline) / baseline.abs() * 100;
    if (pct.abs() < 0.05) return '0% this month';
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% this month';
  }

  /// Income / expense totals over the last [days] days.
  static ({double income, double expenses}) recentTotals(
    List<ParsedTransaction> txs, {
    int days = 7,
  }) {
    final since = DateTime.now().subtract(Duration(days: days));
    double income = 0;
    double expenses = 0;
    for (final tx in txs) {
      final date = DateTime.tryParse(tx.occurredAt);
      if (date == null || date.isBefore(since)) continue;
      if (isIncome(tx)) {
        income += tx.amount;
      } else {
        expenses += tx.amount;
      }
    }
    return (income: income, expenses: expenses);
  }

  /// Total expense amount within a given calendar month.
  static double expensesInMonth(
    List<ParsedTransaction> txs,
    int year,
    int month,
  ) {
    double total = 0;
    for (final tx in txs) {
      if (isIncome(tx)) continue;
      final date = DateTime.tryParse(tx.occurredAt);
      if (date == null) continue;
      if (date.year == year && date.month == month) total += tx.amount;
    }
    return total;
  }

  /// Derives up to [max] real insights from the user's budgets, goals, and
  /// spending history, ordered by urgency (over-budget first, then warnings,
  /// then encouraging progress). Returns an empty list when there's nothing
  /// meaningful to say — the widget shows a neutral prompt in that case.
  static List<DashboardInsight> insights({
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<ParsedTransaction> txs,
    int max = 3,
  }) {
    final danger = <DashboardInsight>[];
    final warning = <DashboardInsight>[];
    final positive = <DashboardInsight>[];

    // Budget alerts.
    for (final b in budgets) {
      if (b.isOverBudget) {
        danger.add(DashboardInsight(
          tone: InsightTone.danger,
          title: '${b.name} over budget',
          message:
              'You\'ve spent ${b.percentageInt}% of your ${b.name.toLowerCase()} '
              'budget. Time to ease off.',
        ));
      } else if (b.isNearLimit) {
        warning.add(DashboardInsight(
          tone: InsightTone.warning,
          title: '${b.name} budget alert',
          message:
              'You\'re at ${b.percentageInt}% of your ${b.name.toLowerCase()} '
              'budget. Try to cut back on non-essentials.',
        ));
      }
    }

    // Month-over-month spending trend.
    final now = DateTime.now();
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final thisMonthExpenses = expensesInMonth(txs, now.year, now.month);
    final lastMonthExpenses =
        expensesInMonth(txs, prevMonthDate.year, prevMonthDate.month);
    if (lastMonthExpenses > 0) {
      final change =
          (thisMonthExpenses - lastMonthExpenses) / lastMonthExpenses * 100;
      if (change >= 10) {
        warning.add(DashboardInsight(
          tone: InsightTone.warning,
          title: 'Spending is up',
          message:
              'You\'re spending ${change.round()}% more than last month so far. '
              'Keep an eye on it.',
        ));
      } else if (change <= -10) {
        positive.add(DashboardInsight(
          tone: InsightTone.positive,
          title: 'Spending is down',
          message:
              'Nice — you\'re spending ${change.abs().round()}% less than last '
              'month. Keep it up!',
        ));
      }
    }

    // Goal progress.
    final activeGoals = goals.where((g) => g.isActive).toList();
    final completed = activeGoals.where((g) => g.isCompleted).toList();
    if (completed.isNotEmpty) {
      positive.add(DashboardInsight(
        tone: InsightTone.positive,
        title: 'Goal reached!',
        message: 'You\'ve hit your "${completed.first.name}" goal. Congratulations!',
      ));
    } else {
      final inProgress = activeGoals.where((g) => g.percentage > 0).toList()
        ..sort((a, b) => b.percentage.compareTo(a.percentage));
      if (inProgress.isNotEmpty) {
        final g = inProgress.first;
        positive.add(DashboardInsight(
          tone: InsightTone.positive,
          title: 'Progress toward ${g.name}',
          message:
              'You\'re ${g.percentageInt}% of the way to "${g.name}". Keep going!',
        ));
      }
    }

    return [...danger, ...warning, ...positive].take(max).toList();
  }

  /// Expense totals grouped by spending category, largest first. Used by the
  /// breakdown donut / list.
  static List<DonutSlice> categoryBreakdown(List<ParsedTransaction> txs) {
    final totals = <String, double>{};
    for (final tx in txs) {
      if (isIncome(tx)) continue;
      final category =
          Budget.getCategoryFromMerchant(tx.merchant, reason: tx.reason);
      totals[category] = (totals[category] ?? 0) + tx.amount;
    }
    final slices = totals.entries
        .map((e) => DonutSlice(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }
}
