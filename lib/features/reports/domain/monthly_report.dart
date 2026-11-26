import '../../categories/domain/category.dart';
import '../../expenses/domain/expense.dart';

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.totalMinorUnits,
    required this.recurringTotalMinorUnits,
    required this.oneTimeTotalMinorUnits,
    required this.expenses,
    required this.categoryTotals,
    required this.merchantTotals,
  });

  final DateTime month;
  final int totalMinorUnits;
  final int recurringTotalMinorUnits;
  final int oneTimeTotalMinorUnits;
  final List<Expense> expenses;
  final List<ReportTotal> categoryTotals;
  final List<ReportTotal> merchantTotals;
}

class ReportTotal {
  const ReportTotal({required this.label, required this.amountMinorUnits});

  final String label;
  final int amountMinorUnits;
}

class MonthlyReportBuilder {
  const MonthlyReportBuilder();

  MonthlyReport build({
    required DateTime month,
    required List<Expense> expenses,
    required List<Category> categories,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final monthExpenses = expenses
        .where(
          (expense) =>
              expense.occurredAt.year == normalizedMonth.year &&
              expense.occurredAt.month == normalizedMonth.month,
        )
        .toList(growable: false);

    final recurringTotal = monthExpenses
        .where((expense) => expense.recurringExpenseId != null)
        .fold<int>(0, (total, expense) => total + expense.amountMinorUnits);
    final total = monthExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountMinorUnits,
    );

    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final categoryTotals = <String, int>{};
    final merchantTotals = <String, int>{};
    for (final expense in monthExpenses) {
      final categoryName = expense.categoryId == null
          ? 'Kategorisiz'
          : categoryNames[expense.categoryId] ?? 'Kategorisiz';
      categoryTotals.update(
        categoryName,
        (amount) => amount + expense.amountMinorUnits,
        ifAbsent: () => expense.amountMinorUnits,
      );
      merchantTotals.update(
        expense.merchant,
        (amount) => amount + expense.amountMinorUnits,
        ifAbsent: () => expense.amountMinorUnits,
      );
    }

    return MonthlyReport(
      month: normalizedMonth,
      totalMinorUnits: total,
      recurringTotalMinorUnits: recurringTotal,
      oneTimeTotalMinorUnits: total - recurringTotal,
      expenses: List.unmodifiable(monthExpenses),
      categoryTotals: _sortedTotals(categoryTotals),
      merchantTotals: _sortedTotals(merchantTotals),
    );
  }

  List<ReportTotal> _sortedTotals(Map<String, int> totals) {
    final entries = totals.entries.toList()
      ..sort((first, second) {
        final amountComparison = second.value.compareTo(first.value);
        return amountComparison != 0
            ? amountComparison
            : first.key.compareTo(second.key);
      });
    return List.unmodifiable(
      entries.map(
        (entry) => ReportTotal(label: entry.key, amountMinorUnits: entry.value),
      ),
    );
  }
}
