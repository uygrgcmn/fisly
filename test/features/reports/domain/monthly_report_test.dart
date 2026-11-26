import 'package:fisly/features/categories/domain/category.dart';
import 'package:fisly/features/expenses/domain/expense.dart';
import 'package:fisly/features/reports/domain/monthly_report.dart';
import 'package:fisly/features/reports/domain/monthly_report_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = [
    Category(
      id: 'food',
      name: 'Yemek',
      isDefault: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  test('summarizes selected month by category, merchant, and expense type', () {
    final expenses = [
      _expense(
        id: 'recurring',
        merchant: 'Netflix',
        amountMinorUnits: 1299,
        occurredAt: DateTime(2026, 11, 5),
        recurringExpenseId: 'subscription',
      ),
      _expense(
        id: 'one-time',
        merchant: 'Cafe',
        amountMinorUnits: 2500,
        occurredAt: DateTime(2026, 11, 8),
        categoryId: 'food',
      ),
      _expense(
        id: 'outside-month',
        merchant: 'Other month',
        amountMinorUnits: 9900,
        occurredAt: DateTime(2026, 10, 31),
      ),
    ];

    final report = const MonthlyReportBuilder().build(
      month: DateTime(2026, 11, 20),
      expenses: expenses,
      categories: categories,
    );

    expect(report.totalMinorUnits, 3799);
    expect(report.recurringTotalMinorUnits, 1299);
    expect(report.oneTimeTotalMinorUnits, 2500);
    expect(
      report.categoryTotals
          .map((total) => (total.label, total.amountMinorUnits))
          .toList(),
      [('Yemek', 2500), ('Kategorisiz', 1299)],
    );
    expect(
      report.merchantTotals
          .map((total) => (total.label, total.amountMinorUnits))
          .toList(),
      [('Cafe', 2500), ('Netflix', 1299)],
    );
    expect(report.expenses, hasLength(2));
  });

  test('generates escaped UTF-8 CSV with category names and expense types', () {
    final report = const MonthlyReportBuilder().build(
      month: DateTime(2026, 11),
      expenses: [
        _expense(
          id: 'one-time',
          merchant: 'Cafe, Inc.',
          amountMinorUnits: 2500,
          occurredAt: DateTime(2026, 11, 8),
          categoryId: 'food',
          note: 'lunch "special"',
        ),
        _expense(
          id: 'recurring',
          merchant: 'Netflix',
          amountMinorUnits: 1299,
          occurredAt: DateTime(2026, 11, 5),
          recurringExpenseId: 'subscription',
        ),
      ],
      categories: categories,
    );

    final csv = const MonthlyReportCsv().generate(
      report,
      categories: categories,
    );

    expect(
      csv.startsWith('\uFEFFDate,Merchant,Category,Amount,Type,Note'),
      isTrue,
    );
    expect(
      csv,
      contains('"Cafe, Inc.",Yemek,25.00,One-time,"lunch ""special"""'),
    );
    expect(csv, contains('Netflix,Uncategorized,12.99,Recurring,'));
  });
}

Expense _expense({
  required String id,
  required String merchant,
  required int amountMinorUnits,
  required DateTime occurredAt,
  String? categoryId,
  String? recurringExpenseId,
  String? note,
}) {
  return Expense(
    id: id,
    merchant: merchant,
    amountMinorUnits: amountMinorUnits,
    currencyCode: 'TRY',
    occurredAt: occurredAt,
    categoryId: categoryId,
    recurringExpenseId: recurringExpenseId,
    note: note,
    createdAt: occurredAt,
    updatedAt: occurredAt,
  );
}
