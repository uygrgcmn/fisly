import 'package:fisly/features/categories/domain/category.dart';
import 'package:fisly/features/dashboard/domain/spending_analytics.dart';
import 'package:fisly/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analytics = SpendingAnalytics();
  final categories = [
    Category(
      id: 'food',
      name: 'Yemek',
      isDefault: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    Category(
      id: 'market',
      name: 'Market',
      isDefault: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  test('summarizes the current month, categories, and six-month trend', () {
    final expenses = [
      _expense(
        id: 'nov-food',
        amountMinorUnits: 1300,
        occurredAt: DateTime(2026, 11, 12),
        categoryId: 'food',
      ),
      _expense(
        id: 'nov-market',
        amountMinorUnits: 2200,
        occurredAt: DateTime(2026, 11, 20),
        categoryId: 'market',
      ),
      _expense(
        id: 'nov-uncategorized',
        amountMinorUnits: 200,
        occurredAt: DateTime(2026, 11, 23),
        categoryId: 'deleted-category',
      ),
      _expense(
        id: 'oct-food',
        amountMinorUnits: 5000,
        occurredAt: DateTime(2026, 10, 30),
        categoryId: 'food',
      ),
      _expense(
        id: 'dec-food',
        amountMinorUnits: 7000,
        occurredAt: DateTime(2026, 12, 1),
        categoryId: 'food',
      ),
    ];

    final summary = analytics.summarize(
      expenses: expenses,
      categories: categories,
      currentDate: DateTime(2026, 11, 25),
    );

    expect(summary.monthlyTotalMinorUnits, 3700);
    expect(
      summary.categoryBreakdown
          .map((item) => (item.categoryName, item.amountMinorUnits))
          .toList(),
      [('Market', 2200), ('Yemek', 1300), ('Kategorisiz', 200)],
    );
    expect(
      summary.monthlyTrend.map((month) => month.amountMinorUnits).toList(),
      [0, 0, 0, 0, 5000, 3700],
    );
    expect(summary.monthlyTrend.first.month, DateTime(2026, 6));
    expect(summary.monthlyTrend.last.month, DateTime(2026, 11));
  });

  test('returns zero totals and empty category breakdown without expenses', () {
    final summary = analytics.summarize(
      expenses: const [],
      categories: categories,
      currentDate: DateTime(2026, 11, 25),
    );

    expect(summary.monthlyTotalMinorUnits, 0);
    expect(summary.categoryBreakdown, isEmpty);
    expect(
      summary.monthlyTrend.every((month) => month.amountMinorUnits == 0),
      isTrue,
    );
  });
}

Expense _expense({
  required String id,
  required int amountMinorUnits,
  required DateTime occurredAt,
  String? categoryId,
}) {
  return Expense(
    id: id,
    merchant: 'Merchant',
    amountMinorUnits: amountMinorUnits,
    currencyCode: 'TRY',
    occurredAt: occurredAt,
    categoryId: categoryId,
    createdAt: occurredAt,
    updatedAt: occurredAt,
  );
}
