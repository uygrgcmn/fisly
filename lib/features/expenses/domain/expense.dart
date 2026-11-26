class Expense {
  const Expense({
    required this.id,
    required this.merchant,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.note,
    this.receiptImagePath,
    this.recurringExpenseId,
  });

  final String id;
  final String merchant;
  final int amountMinorUnits;
  final String currencyCode;
  final DateTime occurredAt;
  final String? categoryId;
  final String? note;
  final String? receiptImagePath;
  final String? recurringExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
