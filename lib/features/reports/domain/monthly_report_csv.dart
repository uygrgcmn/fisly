import '../../categories/domain/category.dart';
import 'monthly_report.dart';

class MonthlyReportCsv {
  const MonthlyReportCsv();

  String generate(MonthlyReport report, {required List<Category> categories}) {
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final rows = <List<String>>[
      ['Date', 'Merchant', 'Category', 'Amount', 'Type', 'Note'],
      for (final expense in report.expenses)
        [
          _formatDate(expense.occurredAt),
          expense.merchant,
          expense.categoryId == null
              ? 'Uncategorized'
              : categoryNames[expense.categoryId] ?? 'Uncategorized',
          _formatAmount(expense.amountMinorUnits),
          expense.recurringExpenseId == null ? 'One-time' : 'Recurring',
          expense.note ?? '',
        ],
    ];

    return '\uFEFF${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}';
  }

  String _escape(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatAmount(int amountMinorUnits) {
    final whole = amountMinorUnits ~/ 100;
    final fraction = (amountMinorUnits % 100).toString().padLeft(2, '0');
    return '$whole.$fraction';
  }
}
