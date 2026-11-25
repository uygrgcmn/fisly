import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../features/categories/domain/category.dart';
import '../../../features/categories/presentation/category_management_sheet.dart';
import '../../../features/categories/presentation/categories_providers.dart';
import '../../../features/dashboard/domain/spending_analytics.dart';
import '../../../features/dashboard/presentation/dashboard_overview.dart';
import '../../../features/expenses/domain/expense.dart';
import '../../../features/expenses/presentation/expense_form_sheet.dart';
import '../../../features/expenses/presentation/expenses_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fisly'),
        actions: [
          IconButton(
            key: const Key('manage-categories-button'),
            tooltip: 'Kategorileri yönet',
            onPressed: () => _showCategoryManagement(context),
            icon: const Icon(Icons.category_outlined),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => categoriesAsync.when(
          data: (categories) =>
              _buildExpenseList(context, ref, expenses, categories),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError('Kategoriler yüklenemedi: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError('Harcamalar yüklenemedi: $error'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-expense-button'),
        onPressed: () => _showExpenseForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Harcama ekle'),
      ),
    );
  }

  Widget _buildExpenseList(
    BuildContext context,
    WidgetRef ref,
    List<Expense> expenses,
    List<Category> categories,
  ) {
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Henüz harcama yok',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Fişlerini ve harcamalarını tek yerde takip et.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: expenses.length + 2,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) return DashboardOverview(summary: summary);
        if (index == 1) {
          return Text(
            'Son harcamalar',
            style: Theme.of(context).textTheme.titleLarge,
          );
        }

        final expense = expenses[index - 2];
        final categoryName = expense.categoryId == null
            ? 'Kategorisiz'
            : categoryNames[expense.categoryId] ?? 'Kategorisiz';

        return Card(
          child: ListTile(
            key: ValueKey('expense-${expense.id}'),
            title: Text(expense.merchant),
            subtitle: Text(
              '$categoryName · ${_formatDate(expense.occurredAt)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatTryMinorUnits(expense.amountMinorUnits)),
                PopupMenuButton<String>(
                  tooltip: 'Harcama işlemleri',
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
