class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.merchant,
    required this.amountMinorUnits,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.note,
    this.lastPaidAt,
  });

  final String id;
  final String merchant;
  final int amountMinorUnits;
  final String? categoryId;
  final String? note;
  final bool isActive;
  final DateTime? lastPaidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool wasPaidInMonth(DateTime month) =>
      isActive &&
      lastPaidAt != null &&
      lastPaidAt!.year == month.year &&
      lastPaidAt!.month == month.month;
}
