import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/amount_parser.dart';
import 'monthly_budgets_providers.dart';

class MonthlyBudgetSheet extends ConsumerStatefulWidget {
  const MonthlyBudgetSheet({this.initialLimitMinorUnits, super.key});

  final int? initialLimitMinorUnits;

  @override
  ConsumerState<MonthlyBudgetSheet> createState() => _MonthlyBudgetSheetState();
}

class _MonthlyBudgetSheetState extends ConsumerState<MonthlyBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final limit = widget.initialLimitMinorUnits;
    _amountController = TextEditingController(
      text: limit == null ? '' : formatAmountInput(limit),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const FislySheetHeader(
                  title: 'Aylık harcama limiti',
                  icon: Icons.account_balance_wallet_rounded,
                  subtitle:
                      'Bu limit her ay için geçerlidir. Harcama kayıtların '
                      'çevrimdışı olarak cihazında saklanır.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('monthly-budget-amount-field'),
                  controller: _amountController,
                  style: tabularAmountStyle(
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Aylık limit (₺)',
                    hintText: 'Örn. 15000,00',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      parseAmountMinorUnits(value ?? '') == null
                      ? 'Geçerli ve sıfırdan büyük bir limit girin.'
                      : null,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  key: const Key('save-monthly-budget-button'),
                  onPressed: _isSaving ? null : _saveBudget,
                  child: Text(_isSaving ? 'Kaydediliyor...' : 'Limiti kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final limitMinorUnits = parseAmountMinorUnits(_amountController.text);
    if (limitMinorUnits == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(monthlyBudgetsRepositoryProvider)
          .setMonthlyLimit(limitMinorUnits);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Limit kaydedilemedi: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
