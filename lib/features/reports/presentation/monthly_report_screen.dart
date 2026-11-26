import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/fisly_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expenses_providers.dart';
import '../domain/monthly_report.dart';
import '../domain/monthly_report_csv.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final colors = context.fislyColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık rapor'),
        actions: [
          IconButton(
            key: const Key('export-monthly-report-button'),
            tooltip: 'CSV olarak paylaş',
            onPressed: expensesAsync.hasValue && categoriesAsync.hasValue
                ? () => _shareReport(
                    expensesAsync.value!,
                    categoriesAsync.value!,
                  )
                : null,
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => categoriesAsync.when(
          data: (categories) => _buildReport(expenses, categories),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError('Kategoriler yüklenemedi: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError('Harcamalar yüklenemedi: $error'),
      ),
    );
  }

  Widget _buildReport(List<Expense> expenses, List<Category> categories) {
    final report = const MonthlyReportBuilder().build(
      month: _selectedMonth,
      expenses: expenses,
      categories: categories,
    );
    final colors = context.fislyColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildMonthSelector(colors),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.heroStart, colors.heroEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.heroEnd.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam harcama',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatTryMinorUnits(report.totalMinorUnits),
                key: const Key('report-monthly-total'),
                style: tabularAmountStyle(
                  Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  children: [
                    _heroSummaryRow(
                      'Düzenli ödemeler',
                      report.recurringTotalMinorUnits,
                    ),
                    const SizedBox(height: 8),
                    _heroSummaryRow(
                      'Tek seferlik',
                      report.oneTimeTotalMinorUnits,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildTotalsCard(
          title: 'Kategoriye göre',
          icon: Icons.category_rounded,
          iconColor: colors.accent,
          emptyText: 'Bu ay için kategori verisi yok.',
          totals: report.categoryTotals,
        ),
        const SizedBox(height: 14),
        _buildTotalsCard(
          title: 'Mağaza veya işletmeye göre',
          icon: Icons.storefront_rounded,
          iconColor: colors.success,
          emptyText: 'Bu ay için harcama yok.',
          totals: report.merchantTotals,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FislyIconBadge(
                  icon: Icons.file_download_outlined,
                  color: colors.textSecondary,
                  size: 38,
                  iconSize: 20,
                  radius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CSV dışa aktarma, bu aya ait harcamaların tarih, mağaza, '
                    'kategori, tutar ve ödeme türü ayrıntılarını paylaşır.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(FislyColors colors) {
    final isCurrentMonth =
        _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              key: const Key('previous-report-month-button'),
              tooltip: 'Önceki ay',
              onPressed: () => setState(
                () => _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                ),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                key: const Key('report-selected-month'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              key: const Key('next-report-month-button'),
              tooltip: 'Sonraki ay',
              onPressed: isCurrentMonth
                  ? null
                  : () => setState(
                      () => _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      ),
                    ),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroSummaryRow(String label, int amountMinorUnits) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
        Text(
          formatTryMinorUnits(amountMinorUnits),
          style: tabularAmountStyle(
            Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, int amountMinorUnits) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
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
    );
  }

  Widget _buildTotalsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String emptyText,
    required List<ReportTotal> totals,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FislyIconBadge(
                  icon: icon,
                  color: iconColor,
                  size: 36,
                  iconSize: 18,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (totals.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  emptyText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else ...[
              const SizedBox(height: 10),
              for (final total in totals)
                _summaryRow(total.label, total.amountMinorUnits),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _shareReport(
    List<Expense> expenses,
    List<Category> categories,
  ) async {
    final report = const MonthlyReportBuilder().build(
      month: _selectedMonth,
      expenses: expenses,
      categories: categories,
    );
    final csv = const MonthlyReportCsv().generate(
      report,
      categories: categories,
    );
    final month =
        '${_selectedMonth.year}-'
        '${_selectedMonth.month.toString().padLeft(2, '0')}';

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Fisly $month harcama raporu',
          files: [XFile.fromData(utf8.encode(csv), mimeType: 'text/csv')],
          fileNameOverrides: ['fisly-report-$month.csv'],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Rapor paylaşılamadı: $error')));
    }
  }

  Widget _buildError(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );

  static const _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
}
