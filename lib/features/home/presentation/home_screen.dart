import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/budgets/domain/monthly_budget.dart';
import '../../../features/budgets/presentation/monthly_budget_card.dart';
import '../../../features/budgets/presentation/monthly_budget_sheet.dart';
import '../../../features/budgets/presentation/monthly_budgets_providers.dart';
import '../../../features/categories/domain/category.dart';
import '../../../features/categories/presentation/categories_providers.dart';
import '../../../features/categories/presentation/category_management_sheet.dart';
import '../../../features/dashboard/domain/spending_analytics.dart';
import '../../../features/dashboard/presentation/dashboard_overview.dart';
import '../../../features/expenses/domain/expense.dart';
import '../../../features/expenses/presentation/expense_form_sheet.dart';
import '../../../features/expenses/presentation/expenses_providers.dart';
import '../../../features/recurring_expenses/domain/recurring_expense.dart';
import '../../../features/recurring_expenses/presentation/recurring_expenses_card.dart';
import '../../../features/recurring_expenses/presentation/recurring_expenses_providers.dart';
import '../../../features/recurring_expenses/presentation/recurring_expenses_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final monthlyBudgetAsync = ref.watch(monthlyBudgetProvider);
    final recurringExpensesAsync = ref.watch(recurringExpensesProvider);
    final colors = context.fislyColors;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.accent, colors.success],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Fisly'),
          ],
        ),
        actions: [
          _HeaderActionButton(
            key: const Key('manage-recurring-expenses-button'),
            tooltip: 'Düzenli ödemeler',
            icon: Icons.autorenew_rounded,
            onPressed: () => _showRecurringExpenses(context),
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            key: const Key('manage-categories-button'),
            tooltip: 'Kategorileri yönet',
            icon: Icons.grid_view_rounded,
            onPressed: () => _showCategoryManagement(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => categoriesAsync.when(
          data: (categories) => monthlyBudgetAsync.when(
            data: (budget) => recurringExpensesAsync.when(
              data: (recurringExpenses) => _buildExpenseList(
                context,
                ref,
                expenses,
                categories,
                budget,
                recurringExpenses,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _buildError('Düzenli ödemeler yüklenemedi: $error'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildError('Aylık limit yüklenemedi: $error'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError('Kategoriler yüklenemedi: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError('Harcamalar yüklenemedi: $error'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-expense-button'),
        onPressed: () => _showExpenseForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Harcama ekle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showRecurringExpenses(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const RecurringExpensesSheet(),
    );
  }

  Future<void> _confirmRecurringPayment(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${expense.merchant}" ödemesi yapıldı mı?'),
        content: Text(
          '${formatTryMinorUnits(expense.amountMinorUnits)} tutarındaki '
          'ödeme bu ayın harcaması olarak kaydedilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-recurring-payment-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, kaydet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final wasRecorded = await ref
          .read(recurringExpensesRepositoryProvider)
          .recordPayment(expense.id, paidAt: DateTime.now());
      if (!wasRecorded) {
        throw StateError(
          'This recurring payment is inactive or already recorded this month.',
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ödeme kaydedilemedi: $error')));
    }
  }

  Widget _buildExpenseList(
    BuildContext context,
    WidgetRef ref,
    List<Expense> expenses,
    List<Category> categories,
    MonthlyBudget? monthlyBudget,
    List<RecurringExpense> recurringExpenses,
  ) {
    final colors = context.fislyColors;

    if (expenses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.accent.withValues(alpha: 0.16),
                          colors.success.withValues(alpha: 0.16),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 38,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Henüz harcama yok',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fişlerini ve harcamalarını tek yerde takip et.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          MonthlyBudgetCard(
            monthlySpentMinorUnits: 0,
            monthlyBudgetMinorUnits: monthlyBudget?.limitMinorUnits,
            onEdit: () => _showMonthlyBudget(context, monthlyBudget),
          ),
          const SizedBox(height: 14),
          RecurringExpensesCard(
            recurringExpenses: recurringExpenses,
            onRecordPayment: (expense) =>
                _confirmRecurringPayment(context, ref, expense),
          ),
        ],
      );
    }

    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final summary = const SpendingAnalytics().summarize(
      expenses: expenses,
      categories: categories,
      currentDate: DateTime.now(),
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: expenses.length + 3,
      separatorBuilder: (context, index) =>
          SizedBox(height: index < 2 ? 14 : 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return DashboardOverview(
            summary: summary,
            monthlyBudgetMinorUnits: monthlyBudget?.limitMinorUnits,
            onEditMonthlyBudget: () =>
                _showMonthlyBudget(context, monthlyBudget),
          );
        }
        if (index == 1) {
          return RecurringExpensesCard(
            recurringExpenses: recurringExpenses,
            onRecordPayment: (expense) =>
                _confirmRecurringPayment(context, ref, expense),
          );
        }
        if (index == 2) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Son harcamalar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FislyPillBadge(
                  label: '${expenses.length} kayıt',
                  foreground: colors.textSecondary,
                  background: colors.surfaceElevated,
                ),
              ],
            ),
          );
        }

        final expense = expenses[index - 3];
        final categoryName = expense.categoryId == null
            ? 'Kategorisiz'
            : categoryNames[expense.categoryId] ?? 'Kategorisiz';
        final visual = FislyCategoryVisual.fromName(categoryName);

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              key: ValueKey('expense-${expense.id}'),
              children: [
                FislyIconBadge(
                  icon: visual.icon,
                  color: visual.color,
                  size: 44,
                  iconSize: 22,
                  radius: 14,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$categoryName · ${_formatDate(expense.occurredAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatTryMinorUnits(expense.amountMinorUnits),
                  style: tabularAmountStyle(
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Harcama işlemleri',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showExpenseForm(context, expense: expense);
                    } else {
                      _confirmDelete(context, ref, expense);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  void _showExpenseForm(BuildContext context, {Expense? expense}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseFormSheet(expense: expense),
    );
  }

  void _showCategoryManagement(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CategoryManagementSheet(),
    );
  }

  void _showMonthlyBudget(BuildContext context, MonthlyBudget? budget) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          MonthlyBudgetSheet(initialLimitMinorUnits: budget?.limitMinorUnits),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harcamayı sil?'),
        content: Text('"${expense.merchant}" kaydı kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-delete-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final wasDeleted = await ref
          .read(expensesRepositoryProvider)
          .deleteExpense(expense.id);
      if (!wasDeleted) {
        throw StateError('The expense no longer exists.');
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Harcama silinemedi: $error')));
    }
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.fislyColors;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
