import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/recurring_expense.dart';

class RecurringExpensesCard extends StatelessWidget {
  const RecurringExpensesCard({
    required this.recurringExpenses,
    required this.onRecordPayment,
    super.key,
  });

  final List<RecurringExpense> recurringExpenses;
  final ValueChanged<RecurringExpense> onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final activeExpenses = recurringExpenses
        .where((expense) => expense.isActive)
        .toList(growable: false);
    final currentMonth = DateTime.now();
    final colors = context.fislyColors;

    return Card(
      key: const Key('recurring-expenses-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FislyIconBadge(
                  icon: Icons.autorenew_rounded,
                  color: colors.warning,
                  size: 36,
                  iconSize: 18,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Düzenli ödemeler',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (activeExpenses.isNotEmpty)
                  FislyPillBadge(
                    label: '${activeExpenses.length}',
                    foreground: colors.textSecondary,
                    background: colors.surfaceElevated,
                  ),
              ],
            ),
            if (activeExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'Henüz düzenli ödeme eklenmedi. Fatura ve aboneliklerini '
                  'düzenli ödemeler bölümünden ekleyebilirsin.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              for (var index = 0; index < activeExpenses.length; index++) ...[
                _RecurringItemRow(
                  expense: activeExpenses[index],
                  isPaidThisMonth:
                      activeExpenses[index].wasPaidInMonth(currentMonth),
                  onRecordPayment: () => onRecordPayment(activeExpenses[index]),
                ),
                if (index < activeExpenses.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RecurringItemRow extends StatelessWidget {
  const _RecurringItemRow({
    required this.expense,
    required this.isPaidThisMonth,
    required this.onRecordPayment,
  });

  final RecurringExpense expense;
  final bool isPaidThisMonth;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final colors = context.fislyColors;

    return Padding(
      key: ValueKey('recurring-expense-${expense.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          FislyIconBadge(
            icon: Icons.event_repeat_rounded,
            color: isPaidThisMonth ? colors.success : colors.accent,
            size: 40,
            iconSize: 20,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.merchant,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatTryMinorUnits(expense.amountMinorUnits)} · Aylık',
                  style: tabularAmountStyle(
                    Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPaidThisMonth)
            FislyPillBadge(
              key: const Key('recurring-expense-paid-status'),
              label: 'Bu ay ödendi',
              icon: Icons.check_circle_rounded,
              foreground: colors.success,
              background: colors.successSoft,
            )
          else
            FilledButton.tonal(
              key: const Key('record-recurring-payment-button'),
              onPressed: onRecordPayment,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Ödemeyi kaydet'),
            ),
        ],
      ),
    );
  }
}
