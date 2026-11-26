import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/amount_parser.dart';
import '../../categories/presentation/categories_providers.dart';
import '../domain/recurring_expense.dart';
import 'recurring_expenses_providers.dart';

class RecurringExpenseFormSheet extends ConsumerStatefulWidget {
  const RecurringExpenseFormSheet({this.expense, super.key});

  final RecurringExpense? expense;

  @override
  ConsumerState<RecurringExpenseFormSheet> createState() =>
      _RecurringExpenseFormSheetState();
}

class _RecurringExpenseFormSheetState
    extends ConsumerState<RecurringExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _categoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _merchantController = TextEditingController(text: expense?.merchant);
    _amountController = TextEditingController(
      text: expense == null ? '' : formatAmountInput(expense.amountMinorUnits),
    );
    _noteController = TextEditingController(text: expense?.note);
    _categoryId = expense?.categoryId;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final colors = context.fislyColors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FislySheetHeader(
                  title: widget.expense == null
                      ? 'Düzenli ödeme ekle'
                      : 'Düzenli ödemeyi düzenle',
                  icon: Icons.event_repeat_rounded,
                  accentColor: colors.warning,
                  subtitle:
                      'Telefon faturası veya abonelik gibi aylık ödemeleri ekle. '
                      'Ödeme gerçekleşince ayrıca onaylayarak harcamalara kaydet.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('recurring-merchant-field'),
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Fatura veya abonelik adı',
                    prefixIcon: Icon(Icons.subscriptions_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bu alan zorunludur.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('recurring-amount-field'),
                  controller: _amountController,
                  style: tabularAmountStyle(
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Aylık tutar (₺)',
                    hintText: 'Örn. 199,99',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      parseAmountMinorUnits(value ?? '') == null
                      ? 'Geçerli ve sıfırdan büyük bir tutar girin.'
                      : null,
                ),
                const SizedBox(height: 14),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    key: const Key('recurring-category-field'),
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Kategori seçilmedi'),
                      ),
                      ...categories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(
                    'Kategoriler yüklenemedi: $error',
                    style: TextStyle(color: colors.danger),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('recurring-note-field'),
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not (isteğe bağlı)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  key: const Key('save-recurring-expense-button'),
                  onPressed: _isSaving || !categoriesAsync.hasValue
                      ? null
                      : _save,
                  child: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseAmountMinorUnits(_amountController.text);
    if (amount == null) return;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(recurringExpensesRepositoryProvider);
      final existing = widget.expense;
      if (existing == null) {
        await repository.addRecurringExpense(
          merchant: _merchantController.text.trim(),
          amountMinorUnits: amount,
          categoryId: _categoryId,
          note: _optionalText(_noteController.text),
        );
      } else {
        final wasUpdated = await repository.updateRecurringExpense(
          RecurringExpense(
            id: existing.id,
            merchant: _merchantController.text.trim(),
            amountMinorUnits: amount,
            categoryId: _categoryId,
            note: _optionalText(_noteController.text),
            isActive: existing.isActive,
            lastPaidAt: existing.lastPaidAt,
            createdAt: existing.createdAt,
            updatedAt: existing.updatedAt,
          ),
        );
        if (!wasUpdated) {
          throw StateError('The recurring expense no longer exists.');
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Düzenli ödeme kaydedilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _optionalText(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }
}
