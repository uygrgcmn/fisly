import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fisly/app.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/database/database_provider.dart';
import 'package:fisly/features/budgets/presentation/monthly_budget_card.dart';
import 'package:fisly/features/expenses/data/receipt_ocr_service.dart';
import 'package:fisly/features/expenses/domain/receipt_scan_result.dart';
import 'package:fisly/features/expenses/presentation/expenses_providers.dart';
import 'package:fisly/features/recurring_expenses/data/recurring_expenses_repository.dart';
import 'package:flutter/foundation.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show Scrollable, SizedBox, Text;
import 'package:material_ui/material_ui.dart' show TextFormField;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('creates, edits, and deletes an expense with a category', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('merchant-field')), 'Cafe');
    await tester.enterText(find.byKey(const Key('amount-field')), '12,34');
    await tester.tap(find.byKey(const Key('category-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yemek').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-monthly-total')), findsOneWidget);
    expect(find.textContaining('Yemek'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cafe'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cafe'), findsOneWidget);
    expect(find.text('₺12,34'), findsWidgets);

    await tester.tap(find.byTooltip('Harcama işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('merchant-field')),
      'Updated Cafe',
    );
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    expect(find.text('Updated Cafe'), findsOneWidget);
    expect(find.text('Cafe'), findsNothing);

    await tester.tap(find.byTooltip('Harcama işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-button')));
    await tester.pumpAndSettle();

    expect(find.text('Henüz harcama yok'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('automatically assigns a category from the merchant name', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('merchant-field')), 'Migros');
    await tester.enterText(find.byKey(const Key('amount-field')), '45,00');

    expect(find.text('Mağaza adına göre otomatik seçildi.'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);

    final saveButton = find.byKey(const Key('save-expense-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('dashboard-monthly-total')))
          .data,
      '₺45,00',
    );
    await tester.scrollUntilVisible(
      find.text('Migros'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Migros'), findsOneWidget);
    expect(find.textContaining('Market ·'), findsOneWidget);
    expect(find.text('₺45,00'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('reads receipt text from gallery and saves its image path', (
    tester,
  ) async {
    final receiptOcrService = _FakeReceiptOcrService(
      const ReceiptScanResult(
        imagePath: '/cache/receipt.jpg',
        rawText:
            'MİGROS TİCARET A.Ş.\nTARİH: 25.11.2026\nGENEL TOPLAM: 45,00 TL',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          receiptOcrServiceProvider.overrideWithValue(receiptOcrService),
        ],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-receipt-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('receipt-gallery-option')));
    await tester.pumpAndSettle();

    expect(receiptOcrService.selectedSource, ReceiptImageSource.gallery);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('receipt-ocr-text-field')),
          )
          .controller!
          .text,
      'MİGROS TİCARET A.Ş.\nTARİH: 25.11.2026\nGENEL TOPLAM: 45,00 TL',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('merchant-field')))
          .controller!
          .text,
      'MİGROS TİCARET A.Ş.',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('amount-field')))
          .controller!
          .text,
      '45,00',
    );
    expect(find.text('Tarih: 25.11.2026'), findsOneWidget);
    expect(receiptOcrService.persistedImagePath, isNull);

    await tester.enterText(
      find.byKey(const Key('merchant-field')),
      'Migros Market',
    );
    await tester.enterText(find.byKey(const Key('amount-field')), '50,25');
    await tester.ensureVisible(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    final rows = await database.select(database.expenses).get();
    expect(rows.single.merchant, 'Migros Market');
    expect(rows.single.amountMinorUnits, 5025);
    expect(rows.single.occurredAt, DateTime(2026, 11, 25));
    expect(rows.single.receiptImagePath, '/app-support/receipt.jpg');
    expect(receiptOcrService.persistedImagePath, '/cache/receipt.jpg');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('shows monthly budget progress after adding an expense', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage-monthly-budget-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('monthly-budget-amount-field')),
      '50,00',
    );
    await tester.tap(find.byKey(const Key('save-monthly-budget-button')));
    await tester.pumpAndSettle();

    expect(find.text('₺50,00'), findsOneWidget);
    expect(find.text('Kalan: ₺50,00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-expense-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('merchant-field')),
      'Monthly subscription',
    );
    await tester.enterText(find.byKey(const Key('amount-field')), '75,00');
    await tester.ensureVisible(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('dashboard-monthly-total')))
          .data,
      '₺75,00',
    );
    expect(find.text('Limit ₺25,00 aşıldı.'), findsOneWidget);
    expect(find.byType(MonthlyBudgetCard), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('confirms a recurring payment and updates dashboard totals', (
    tester,
  ) async {
    final recurringRepository = RecurringExpensesRepository(database);
    await recurringRepository.addRecurringExpense(
      merchant: 'Netflix',
      amountMinorUnits: 1299,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('record-recurring-payment-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-recurring-payment-button')));
    await tester.pumpAndSettle();
    expect(find.text('"Netflix" ödemesi yapıldı mı?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-recurring-payment-button')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('dashboard-monthly-total')))
          .data,
      '₺12,99',
    );
    await tester.scrollUntilVisible(
      find.text('Bu ay ödendi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Bu ay ödendi'), findsOneWidget);
    expect(find.text('Netflix'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('adds a recurring monthly payment template', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-management-menu')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('manage-recurring-expenses-menu-item')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-recurring-expense-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recurring-merchant-field')),
      'Telefon faturası',
    );
    await tester.enterText(
      find.byKey(const Key('recurring-amount-field')),
      '450,00',
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-recurring-expense-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-recurring-expense-button')));
    await tester.pumpAndSettle();

    expect(find.text('Telefon faturası'), findsWidgets);
    final templates = await database.select(database.recurringExpenses).get();
    expect(templates, hasLength(1));
    expect(templates.single.amountMinorUnits, 45000);
    expect(templates.single.isActive, isTrue);
    expect(await database.select(database.expenses).get(), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

class _FakeReceiptOcrService implements ReceiptOcrService {
  _FakeReceiptOcrService(this.result);

  final ReceiptScanResult result;
  ReceiptImageSource? selectedSource;
  String? persistedImagePath;

  @override
  Future<ReceiptScanResult?> scan(ReceiptImageSource source) async {
    selectedSource = source;
    return result;
  }

  @override
  Future<String> persistImage(String imagePath) async {
    persistedImagePath = imagePath;
    return '/app-support/receipt.jpg';
  }
}
