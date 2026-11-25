import '../../categories/domain/category.dart';
import '../../expenses/domain/expense.dart';

class SpendingSummary {
  const SpendingSummary({
    required this.currentMonth,
    required this.monthlyTotalMinorUnits,
    required this.categoryBreakdown,
    required this.monthlyTrend,
  });

  final DateTime currentMonth;
  final int monthlyTotalMinorUnits;
  final List<CategorySpending> categoryBreakdown;
  final List<MonthlySpending> monthlyTrend;
}

class CategorySpending {
  const CategorySpending({
    required this.categoryName,
    required this.amountMinorUnits,
  });

  final String categoryName;
  final int amountMinorUnits;
}

class MonthlySpending {
  const MonthlySpending({required this.month, required this.amountMinorUnits});

  final DateTime month;
  final int amountMinorUnits;
}

class SpendingAnalytics {
  const SpendingAnalytics();

  static const _trendMonthCount = 6;

  SpendingSummary summarize({
    required List<Expense> expenses,
    required List<Category> categories,
    required DateTime currentDate,
  }) {
    final currentMonth = DateTime(currentDate.year, currentDate.month);
    final currentMonthExpenses = expenses
        .where((expense) => _isSameMonth(expense.occurredAt, currentMonth))
        .toList(growable: false);
    final monthlyTotal = currentMonthExpenses.fold<int>(
      0,
      (total, expense) => total + expense.amountMinorUnits,
    );

    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final categoryTotals = <String, int>{};
    for (final expense in currentMonthExpenses) {
      final categoryName = expense.categoryId == null
          ? 'Kategorisiz'
          : categoryNames[expense.categoryId] ?? 'Kategorisiz';
      categoryTotals.update(
        categoryName,
        (total) => total + expense.amountMinorUnits,
        ifAbsent: () => expense.amountMinorUnits,
      );
    }

    final categoryBreakdown =
        categoryTotals.entries
            .where((entry) => entry.value > 0)
            .map(
              (entry) => CategorySpending(
                categoryName: entry.key,
                amountMinorUnits: entry.value,
              ),
            )
            .toList()
          ..sort((first, second) {
            final amountComparison = second.amountMinorUnits.compareTo(
              first.amountMinorUnits,
            );
            return amountComparison != 0
                ? amountComparison
                : first.categoryName.compareTo(second.categoryName);
          });

    final firstTrendMonth = DateTime(
      currentMonth.year,
      currentMonth.month - _trendMonthCount + 1,
    );
    final monthlyTrend = List<MonthlySpending>.generate(_trendMonthCount, (
      index,
    ) {
      final month = DateTime(
        firstTrendMonth.year,
        firstTrendMonth.month + index,
      );
      final total = expenses
          .where((expense) => _isSameMonth(expense.occurredAt, month))
          .fold<int>(0, (sum, expense) => sum + expense.amountMinorUnits);
      return MonthlySpending(month: month, amountMinorUnits: total);
    }, growable: false);

    return SpendingSummary(
      currentMonth: currentMonth,
      monthlyTotalMinorUnits: monthlyTotal,
      categoryBreakdown: List.unmodifiable(categoryBreakdown),
      monthlyTrend: List.unmodifiable(monthlyTrend),
    );
  }

  bool _isSameMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }
}
