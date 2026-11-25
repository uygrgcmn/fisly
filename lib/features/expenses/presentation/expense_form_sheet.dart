import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/categories/presentation/categories_providers.dart';
import '../domain/expense.dart';
import 'expenses_providers.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _occurredAt;
  String? _categoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _merchantController = TextEditingController(text: expense?.merchant);
    _amountController = TextEditingController(
      text: expense == null ? '' : _formatAmount(expense.amountMinorUnits),
    );
    _noteController = TextEditingController(text: expense?.note);
    _occurredAt = expense?.occurredAt ?? DateTime.now();
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.expense == null ? 'Harcama ekle' : 'Harcamayı düzenle',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('merchant-field'),
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Mağaza veya işletme',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bu alan zorunludur.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('amount-field'),
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Tutar (₺)',
                    hintText: 'Örn. 125,50',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      _parseAmountMinorUnits(value ?? '') == null
                      ? 'Geçerli bir tutar girin.'
                      : null,
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    key: const Key('category-field'),
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Tarih: ${_formatDate(_occurredAt)}'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('note-field'),
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not (isteğe bağlı)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('save-expense-button'),
                  onPressed: _isSaving || !categoriesAsync.hasValue
                      ? null
                      : _saveExpense,
                  child: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (selectedDate != null) {
      setState(() => _occurredAt = selectedDate);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amountMinorUnits = _parseAmountMinorUnits(_amountController.text);
    if (amountMinorUnits == null) return;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(expensesRepositoryProvider);
      final existingExpense = widget.expense;
      if (existingExpense == null) {
        await repository.addExpense(
          merchant: _merchantController.text.trim(),
          amountMinorUnits: amountMinorUnits,
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          note: _optionalText(_noteController.text),
        );
      } else {
        final updated = Expense(
          id: existingExpense.id,
          merchant: _merchantController.text.trim(),
          amountMinorUnits: amountMinorUnits,
          currencyCode: existingExpense.currencyCode,
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          note: _optionalText(_noteController.text),
          receiptImagePath: existingExpense.receiptImagePath,
          createdAt: existingExpense.createdAt,
          updatedAt: existingExpense.updatedAt,
        );
        final wasUpdated = await repository.updateExpense(updated);
        if (!wasUpdated) {
          throw StateError('The expense no longer exists.');
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Harcama kaydedilemedi: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

int? _parseAmountMinorUnits(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  final parts = normalized.split('.');
  if (parts.length > 2) return null;

  final wholeText = parts.first.isEmpty ? '0' : parts.first;
  final fractionText = parts.length == 1 ? '' : parts.last;
  if (!RegExp(r'^\d+$').hasMatch(wholeText) ||
      (fractionText.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionText)) ||
      fractionText.length > 2) {
    return null;
  }

  final wholeUnits = int.tryParse(wholeText);
  final minorUnits = int.tryParse(fractionText.padRight(2, '0')) ?? 0;
  if (wholeUnits == null ||
      (wholeUnits == 0 && minorUnits == 0) ||
      wholeUnits > (0x7fffffffffffffff - minorUnits) ~/ 100) {
    return null;
  }

  return wholeUnits * 100 + minorUnits;
}

String _formatAmount(int amountMinorUnits) {
  final wholeUnits = amountMinorUnits ~/ 100;
  final minorUnits = (amountMinorUnits % 100).toString().padLeft(2, '0');
  return '$wholeUnits,$minorUnits';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String? _optionalText(String input) {
  final value = input.trim();
  return value.isEmpty ? null : value;
}
