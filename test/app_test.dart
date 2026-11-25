import 'package:fisly/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Turkish home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FislyApp()));

    expect(find.text('Fisly'), findsOneWidget);
    expect(
      find.text('Merhaba Uygar, yeni uygulamana hoş geldin!'),
      findsOneWidget,
    );
    expect(
      find.text('Fişlerini ve harcamalarını tek yerde takip et.'),
      findsOneWidget,
    );
  });
}
