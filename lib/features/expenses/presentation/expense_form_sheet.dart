import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../features/categories/domain/category.dart';
import '../../../features/categories/domain/merchant_category_matcher.dart';
import '../../../features/categories/presentation/categories_providers.dart';
import '../domain/expense.dart';
import '../domain/receipt_parser.dart';
import '../domain/receipt_scan_result.dart';
import 'expenses_providers.dart';

const _merchantCategoryMatcher = MerchantCategoryMatcher();
const _receiptParser = ReceiptParser();

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
      text: expense == null ? '' : formatAmountInput(expense.amountMinorUnits),
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
    final colors = context.fislyColors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FislySheetHeader(
                  title: widget.expense == null
                      ? 'Harcama ekle'
                      : 'Harcamayı düzenle',
                  icon: widget.expense == null
                      ? Icons.add_card_rounded
                      : Icons.edit_note_rounded,
                ),
                const SizedBox(height: 14),
                if (widget.expense == null) ...[
                  OutlinedButton.icon(
                    key: const Key('scan-receipt-button'),
                    onPressed: _isRecognizingReceipt
                        ? null
                        : _selectReceiptImage,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors.accentSoft,
                      foregroundColor: colors.accent,
                      side: BorderSide(
                        color: colors.accent.withValues(alpha: 0.25),
                      ),
                      minimumSize: const Size(0, 46),
                    ),
                    icon: const Icon(Icons.document_scanner_rounded),
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Bulunan alanları kaydetmeden önce kontrol edip düzenleyebilirsin.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('merchant-field'),
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Mağaza veya işletme',
                    prefixIcon: Icon(Icons.storefront_rounded),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bu alan zorunludur.'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('amount-field'),
                  controller: _amountController,
                  style: tabularAmountStyle(
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tutar (₺)',
                    hintText: 'Örn. 125,50',
                    prefixIcon: Icon(Icons.payments_outlined),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      parseAmountMinorUnits(value ?? '') == null
                      ? 'Geçerli bir tutar girin.'
                      : null,
                ),
                const SizedBox(height: 10),
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
                        prefixIcon: const Icon(Icons.category_outlined),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        helperText:
                            suggestedCategory == null ||
                                _categoryWasManuallySelected
                            ? null
                            : 'Mağaza adına göre otomatik seçildi.',
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
                    style: TextStyle(color: colors.danger),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    backgroundColor: colors.surfaceElevated,
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text('Tarih: ${_formatDate(_occurredAt)}'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('note-field'),
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not (isteğe bağlı)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
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
    final colors = context.fislyColors;
    final source = await showModalBottomSheet<ReceiptImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('receipt-camera-option'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: FislyIconBadge(
                  icon: Icons.camera_alt_rounded,
                  color: colors.accent,
                  size: 40,
                  iconSize: 20,
                  radius: 12,
                ),
                title: const Text('Kamerayla çek'),
                onTap: () => Navigator.pop(context, ReceiptImageSource.camera),
              ),
              const SizedBox(height: 4),
              ListTile(
                key: const Key('receipt-gallery-option'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: FislyIconBadge(
                  icon: Icons.photo_library_rounded,
                  color: colors.success,
                  size: 40,
                  iconSize: 20,
                  radius: 12,
                ),
                title: const Text('Galeriden seç'),
                onTap: () => Navigator.pop(context, ReceiptImageSource.gallery),
              ),
            ],
          ),
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
        final parsedReceipt = _receiptParser.parse(result.rawText);
        if (parsedReceipt.merchant != null) {
          _merchantController.text = parsedReceipt.merchant!;
        }
        if (parsedReceipt.totalMinorUnits != null) {
          _amountController.text = formatAmountInput(
            parsedReceipt.totalMinorUnits!,
          );
        }
        if (parsedReceipt.occurredAt != null) {
          _occurredAt = parsedReceipt.occurredAt!;
        }
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

    final amountMinorUnits = parseAmountMinorUnits(_amountController.text);
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
          recurringExpenseId: existingExpense.recurringExpenseId,
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String? _optionalText(String input) {
  final value = input.trim();
  return value.isEmpty ? null : value;
}
