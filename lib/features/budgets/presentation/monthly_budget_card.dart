import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/currency_formatter.dart';

class MonthlyBudgetCard extends StatelessWidget {
  const MonthlyBudgetCard({
    required this.monthlySpentMinorUnits,
    required this.monthlyBudgetMinorUnits,
    required this.onEdit,
    super.key,
  });

  final int monthlySpentMinorUnits;
  final int? monthlyBudgetMinorUnits;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final budget = monthlyBudgetMinorUnits;
    final remaining = budget == null ? null : budget - monthlySpentMinorUnits;
    final progress = budget == null
        ? null
        : (monthlySpentMinorUnits / budget).clamp(0.0, 1.0);
    final isOverBudget = remaining != null && remaining < 0;
    final colors = context.fislyColors;
    final statusColor = isOverBudget ? colors.danger : colors.success;
    final statusSoft = isOverBudget ? colors.dangerSoft : colors.successSoft;
    final percentText = budget == null || budget == 0
        ? null
        : '%${((monthlySpentMinorUnits / budget) * 100).round()}';

    return Card(
      key: const Key('monthly-budget-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FislyIconBadge(
                  icon: Icons.account_balance_wallet_rounded,
                  color: isOverBudget ? colors.danger : colors.accent,
                  size: 36,
                  iconSize: 18,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    budget == null ? 'Aylık limit belirlenmedi' : 'Aylık limit',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const Key('manage-monthly-budget-button'),
                  onPressed: onEdit,
                  icon: Icon(
                    budget == null ? Icons.add_rounded : Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(budget == null ? 'Belirle' : 'Düzenle'),
                ),
              ],
            ),
            if (budget != null && remaining != null && progress != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      formatTryMinorUnits(budget),
                      key: const Key('monthly-budget-limit'),
                      style: tabularAmountStyle(
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (percentText != null)
                    FislyPillBadge(
                      label: percentText,
                      foreground: statusColor,
                      background: statusSoft,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  key: const Key('monthly-budget-progress'),
                  value: progress,
                  minHeight: 10,
                  color: isOverBudget ? colors.danger : colors.accent,
                  backgroundColor: colors.surfaceElevated,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    isOverBudget
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isOverBudget
                          ? 'Limit ${formatTryMinorUnits(remaining.abs())} aşıldı.'
                          : 'Kalan: ${formatTryMinorUnits(remaining)}',
                      key: const Key('monthly-budget-remaining'),
                      style: tabularAmountStyle(
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isOverBudget
                              ? colors.danger
                              : colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
