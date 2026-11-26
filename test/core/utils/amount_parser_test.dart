import 'package:fisly/core/utils/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses decimal input as minor units', () {
    expect(parseAmountMinorUnits('15000,50'), 1500050);
    expect(parseAmountMinorUnits('15000.5'), 1500050);
  });

  test('rejects zero, malformed values, and more than two decimals', () {
    expect(parseAmountMinorUnits('0'), isNull);
    expect(parseAmountMinorUnits('10,999'), isNull);
    expect(parseAmountMinorUnits('1.2.3'), isNull);
    expect(parseAmountMinorUnits('abc'), isNull);
  });
}
