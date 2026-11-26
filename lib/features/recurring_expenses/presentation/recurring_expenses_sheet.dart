import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/recurring_expense.dart';
import 'recurring_expense_form_sheet.dart';
import 'recurring_expenses_providers.dart';

class RecurringExpensesSheet extends ConsumerWidget {
  const RecurringExpensesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(recurringExpensesProvider);
    final colors = context.fislyColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FislySheetHeader(
              title: 'Düzenli ödemeler',
              icon: Icons.autorenew_rounded,
              accentColor: colors.warning,
              subtitle:
                  'Ödeme yaptığında ana ekrandan onayla; harcama o zaman '
                  'aylık raporlarına eklenir.',
              trailing: IconButton.filledTonal(
                key: const Key('add-recurring-expense-button'),
                tooltip: 'Düzenli ödeme ekle',
                onPressed: () => _showForm(context),
                style: IconButton.styleFrom(
                  backgroundColor: colors.accentSoft,
                  foregroundColor: colors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            const SizedBox(height: 16),
            expensesAsync.when(
              data: (expenses) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: expenses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Henüz düzenli ödeme eklenmedi.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: expenses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return _RecurringExpenseTile(
                            expense: expense,
                            onEdit: () => _showForm(context, expense: expense),
                            onToggleActive: () =>
                                _toggleActive(context, ref, expense),
                          );
                        },
                      ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Düzenli ödemeler yüklenemedi: $error',
                style: TextStyle(color: colors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {RecurringExpense? expense}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecurringExpenseFormSheet(expense: expense),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense expense,
  ) async {
    try {
      final wasUpdated = await ref
          .read(recurringExpensesRepositoryProvider)
          .setActive(expense.id, isActive: !expense.isActive);
      if (!wasUpdated) {
        throw StateError('The recurring expense no longer exists.');
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Düzenli ödeme güncellenemedi: $error')),
      );
    }
  }
}

class _RecurringExpenseTile extends StatelessWidget {
  const _RecurringExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onToggleActive,
  });

  final RecurringExpense expense;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.fislyColors;

    return Container(
      key: ValueKey('recurring-expense-management-${expense.id}'),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          FislyIconBadge(
            icon: Icons.event_repeat_rounded,
            color: expense.isActive ? colors.accent : colors.textSecondary,
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
                  formatTryMinorUnits(expense.amountMinorUnits),
                  style: tabularAmountStyle(
                    Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          FislyPillBadge(
            label: expense.isActive ? 'Aktif' : 'Pasif',
            foreground:
                expense.isActive ? colors.success : colors.textSecondary,
            background: expense.isActive ? colors.successSoft : colors.surface,
          ),
          PopupMenuButton<String>(
            tooltip: 'Düzenli ödeme işlemleri',
            icon: Icon(
              Icons.more_vert_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
            onSelected: (action) {
              if (action == 'edit') {
                onEdit();
              } else {
                onToggleActive();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(expense.isActive ? 'Pasifleştir' : 'Etkinleştir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
