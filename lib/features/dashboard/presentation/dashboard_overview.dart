import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budgets/presentation/monthly_budget_card.dart';
import '../domain/spending_analytics.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({
    required this.summary,
    required this.monthlyBudgetMinorUnits,
    required this.onEditMonthlyBudget,
    super.key,
  });

  final SpendingSummary summary;
  final int? monthlyBudgetMinorUnits;
  final VoidCallback onEditMonthlyBudget;

  static const _monthNames = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.fislyColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(context, colors),
        const SizedBox(height: 14),
        MonthlyBudgetCard(
          monthlySpentMinorUnits: summary.monthlyTotalMinorUnits,
          monthlyBudgetMinorUnits: monthlyBudgetMinorUnits,
          onEdit: onEditMonthlyBudget,
        ),
        const SizedBox(height: 14),
        _buildCategoryBreakdown(context, colors),
        const SizedBox(height: 14),
        _buildMonthlyTrend(context, colors),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, FislyColors colors) {
    final monthLabel =
        '${_monthNames[summary.currentMonth.month - 1]} ${summary.currentMonth.year}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroStart, colors.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.heroEnd.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -28,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -48,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.success.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bu ay toplam harcama',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          monthLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    formatTryMinorUnits(summary.monthlyTotalMinorUnits),
                    key: const Key('dashboard-monthly-total'),
                    style: tabularAmountStyle(
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, FislyColors colors) {
    final total = summary.monthlyTotalMinorUnits;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FislyIconBadge(
                  icon: Icons.donut_large_rounded,
                  color: colors.accent,
                  size: 36,
                  iconSize: 18,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Text(
                  'Kategori dağılımı',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (summary.categoryBreakdown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Bu ay kategori harcaması yok.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 48,
                        sectionsSpace: 3,
                        borderData: FlBorderData(show: false),
                        sections: [
                          for (
                            var index = 0;
                            index < summary.categoryBreakdown.length;
                            index++
                          )
                            PieChartSectionData(
                              value: summary
                                  .categoryBreakdown[index]
                                  .amountMinorUnits
                                  .toDouble(),
                              color: _chartColor(index),
                              radius: 34,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${summary.categoryBreakdown.length}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Kategori',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (
                var index = 0;
                index < summary.categoryBreakdown.length;
                index++
              ) ...[
                _CategoryBreakdownRow(
                  name: summary.categoryBreakdown[index].categoryName,
                  amountMinorUnits:
                      summary.categoryBreakdown[index].amountMinorUnits,
                  totalMinorUnits: total,
                  color: _chartColor(index),
                ),
                if (index < summary.categoryBreakdown.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrend(BuildContext context, FislyColors colors) {
    final maxAmount = summary.monthlyTrend.fold<int>(
      0,
      (maximum, month) =>
          month.amountMinorUnits > maximum ? month.amountMinorUnits : maximum,
    );
    final chartMaxY = maxAmount == 0 ? 1.0 : maxAmount * 1.18;
    final lastIndex = summary.monthlyTrend.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FislyIconBadge(
                  icon: Icons.bar_chart_rounded,
                  color: colors.success,
                  size: 36,
                  iconSize: 18,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Text('Son 6 ay', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 196,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 3,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.border,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= summary.monthlyTrend.length) {
                            return const SizedBox.shrink();
                          }
                          final isCurrentMonth = index == lastIndex;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _monthNames[summary
                                      .monthlyTrend[index]
                                      .month
                                      .month -
                                  1],
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isCurrentMonth
                                        ? colors.accent
                                        : colors.textSecondary,
                                    fontWeight: isCurrentMonth
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (
                      var index = 0;
                      index < summary.monthlyTrend.length;
                      index++
                    )
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: summary.monthlyTrend[index].amountMinorUnits
                                .toDouble(),
                            color: index == lastIndex
                                ? colors.accent
                                : colors.accent.withValues(alpha: 0.30),
                            width: 22,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _chartColor(int index) {
    return fislyPalette[index % fislyPalette.length];
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.name,
    required this.amountMinorUnits,
    required this.totalMinorUnits,
    required this.color,
  });

  final String name;
  final int amountMinorUnits;
  final int totalMinorUnits;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.fislyColors;
    final ratio = totalMinorUnits <= 0
        ? 0.0
        : (amountMinorUnits / totalMinorUnits).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '%$percent',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatTryMinorUnits(amountMinorUnits),
              style: tabularAmountStyle(
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            color: color,
            backgroundColor: colors.surfaceElevated,
          ),
        ),
      ],
    );
  }
}
