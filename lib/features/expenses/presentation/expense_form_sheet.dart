import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/categories/domain/category.dart';
import '../../../features/categories/domain/merchant_category_matcher.dart';
import '../../../features/categories/presentation/categories_providers.dart';
import '../domain/expense.dart';
import '../domain/receipt_scan_result.dart';
import 'expenses_providers.dart';

const _merchantCategoryMatcher = MerchantCategoryMatcher();

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
  late final TextEditingController _receiptOcrTextController;
  late DateTime _occurredAt;
  String? _categoryId;
  String? _receiptImagePath;
  bool _receiptImageIsPersistent = false;
  bool _categoryWasManuallySelected = false;
  bool _isRecognizingReceipt = false;
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
    _receiptOcrTextController = TextEditingController();
    _occurredAt = expense?.occurredAt ?? DateTime.now();
    _categoryId = expense?.categoryId;
    _receiptImagePath = expense?.receiptImagePath;
    _categoryWasManuallySelected = expense != null;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _receiptOcrTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.asData?.value ?? const <Category>[];
    final suggestedCategory = _suggestedCategory(categories);
    final selectedCategoryId = _categoryWasManuallySelected
        ? _categoryId
        : suggestedCategory?.id;

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
                if (widget.expense == null) ...[
                  OutlinedButton.icon(
                    key: const Key('scan-receipt-button'),
                    onPressed: _isRecognizingReceipt
                        ? null
                        : _selectReceiptImage,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Fişten metin oku'),
                  ),
                  if (_isRecognizingReceipt)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Fiş okunuyor...'),
                        ],
                      ),
                    ),
                  if (_receiptImagePath != null) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('receipt-ocr-text-field'),
                      controller: _receiptOcrTextController,
                      readOnly: true,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Fişten çıkarılan ham metin',
                        helperText: _receiptOcrTextController.text.isEmpty
                            ? 'Görsel eklendi, ancak metin okunamadı.'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const Key('merchant-field'),
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Mağaza veya işletme',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
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
                  data: (categories) => KeyedSubtree(
                    key: const Key('category-field'),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String?>(
                        'category-dropdown-${selectedCategoryId ?? 'none'}',
                      ),
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        helperText:
                            suggestedCategory == null ||
                                _categoryWasManuallySelected
                            ? null
                            : 'Mağaza adına göre otomatik seçildi.',
                        border: const OutlineInputBorder(),
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
                      onChanged: (value) {
                        setState(() {
                          _categoryId = value;
                          _categoryWasManuallySelected = true;
                        });
                      },
                    ),
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
                  onPressed:
                      _isSaving ||
                          !categoriesAsync.hasValue ||
                          _isRecognizingReceipt
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

  Future<void> _selectReceiptImage() async {
    final source = await showModalBottomSheet<ReceiptImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('receipt-camera-option'),
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamerayla çek'),
              onTap: () => Navigator.pop(context, ReceiptImageSource.camera),
            ),
            ListTile(
              key: const Key('receipt-gallery-option'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(context, ReceiptImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    await _scanReceipt(source);
  }

  Future<void> _scanReceipt(ReceiptImageSource source) async {
    setState(() => _isRecognizingReceipt = true);
    try {
      final result = await ref.read(receiptOcrServiceProvider).scan(source);
      if (result == null || !mounted) return;

      setState(() {
        _receiptImagePath = result.imagePath;
        _receiptImageIsPersistent = false;
        _receiptOcrTextController.text = result.rawText;
      });
      if (result.rawText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fiş eklendi, ancak metin okunamadı.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fiş okunamadı: $error')));
    } finally {
      if (mounted) setState(() => _isRecognizingReceipt = false);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amountMinorUnits = _parseAmountMinorUnits(_amountController.text);
    if (amountMinorUnits == null) return;
    final categories = ref.read(categoriesProvider).asData?.value ?? const [];
    final suggestedCategory = _suggestedCategory(categories);
    final categoryId = _categoryWasManuallySelected
        ? _categoryId
        : suggestedCategory?.id;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(expensesRepositoryProvider);
      final existingExpense = widget.expense;
      if (existingExpense == null) {
        if (_receiptImagePath != null && !_receiptImageIsPersistent) {
          _receiptImagePath = await ref
              .read(receiptOcrServiceProvider)
              .persistImage(_receiptImagePath!);
          _receiptImageIsPersistent = true;
        }
        await repository.addExpense(
          merchant: _merchantController.text.trim(),
          amountMinorUnits: amountMinorUnits,
          occurredAt: _occurredAt,
          categoryId: categoryId,
          note: _optionalText(_noteController.text),
          receiptImagePath: _receiptImagePath,
        );
      } else {
        final updated = Expense(
          id: existingExpense.id,
          merchant: _merchantController.text.trim(),
          amountMinorUnits: amountMinorUnits,
          currencyCode: existingExpense.currencyCode,
          occurredAt: _occurredAt,
          categoryId: categoryId,
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

  Category? _suggestedCategory(List<Category> categories) {
    if (_categoryWasManuallySelected || widget.expense != null) return null;

    final suggestedName = _merchantCategoryMatcher.suggestCategoryName(
      _merchantController.text,
    );
    if (suggestedName == null) return null;

    for (final category in categories) {
      if (category.isDefault && category.name == suggestedName) {
        return category;
      }
    }
    return null;
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
