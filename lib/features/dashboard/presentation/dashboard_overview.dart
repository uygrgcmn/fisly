import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/currency_formatter.dart';
import '../domain/spending_analytics.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({required this.summary, super.key});

  final SpendingSummary summary;

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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu ay toplam harcama',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_monthNames[summary.currentMonth.month - 1]} '
                  '${summary.currentMonth.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formatTryMinorUnits(summary.monthlyTotalMinorUnits),
                  key: const Key('dashboard-monthly-total'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryBreakdown(context, colorScheme),
        const SizedBox(height: 12),
        _buildMonthlyTrend(context, colorScheme),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori dağılımı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (summary.categoryBreakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Bu ay kategori harcaması yok.')),
              )
            else ...[
              SizedBox(
                height: 190,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: double.infinity,
                    sectionsSpace: 2,
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
                          color: _chartColor(colorScheme, index),
                          radius: 60,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (
                var index = 0;
                index < summary.categoryBreakdown.length;
                index++
              )
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _chartColor(colorScheme, index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary.categoryBreakdown[index].categoryName,
                        ),
                      ),
                      Text(
                        formatTryMinorUnits(
                          summary.categoryBreakdown[index].amountMinorUnits,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrend(BuildContext context, ColorScheme colorScheme) {
    final maxAmount = summary.monthlyTrend.fold<int>(
      0,
      (maximum, month) =>
          month.amountMinorUnits > maximum ? month.amountMinorUnits : maximum,
    );
    final chartMaxY = maxAmount == 0 ? 1.0 : maxAmount * 1.15;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Son 6 ay', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
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
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _monthNames[summary
                                      .monthlyTrend[index]
                                      .month
                                      .month -
                                  1],
                              style: Theme.of(context).textTheme.bodySmall,
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
                            color: colorScheme.primary,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
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

  Color _chartColor(ColorScheme colorScheme, int index) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.outline,
    ];
    return colors[index % colors.length];
  }
}
