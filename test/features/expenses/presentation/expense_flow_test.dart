import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fisly/app.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/database/database_provider.dart';
import 'package:fisly/features/expenses/data/receipt_ocr_service.dart';
import 'package:fisly/features/expenses/domain/receipt_scan_result.dart';
import 'package:fisly/features/expenses/presentation/expenses_providers.dart';
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

    await tester.tap(find.byKey(const Key('save-expense-button')));
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
        rawText: 'MIGROS\nTOPLAM 45,00 TL',
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
      'MIGROS\nTOPLAM 45,00 TL',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('merchant-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(receiptOcrService.persistedImagePath, isNull);

    await tester.enterText(find.byKey(const Key('merchant-field')), 'Migros');
    await tester.enterText(find.byKey(const Key('amount-field')), '45,00');
    await tester.ensureVisible(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    final rows = await database.select(database.expenses).get();
    expect(rows.single.receiptImagePath, '/app-support/receipt.jpg');
    expect(receiptOcrService.persistedImagePath, '/cache/receipt.jpg');

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
