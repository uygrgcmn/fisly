import 'package:fisly/features/categories/domain/merchant_category_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const matcher = MerchantCategoryMatcher();

  test('matches common Turkish merchants regardless of letter case', () {
    expect(matcher.suggestCategoryName('MİGROS'), 'Market');
    expect(matcher.suggestCategoryName('Şok Market'), 'Market');
    expect(matcher.suggestCategoryName('İGDAŞ'), 'Faturalar');
    expect(matcher.suggestCategoryName('Cafe Mavi'), 'Yemek');
  });

  test('returns no suggestion for an unknown merchant', () {
    expect(matcher.suggestCategoryName('Bilinmeyen İşletme'), isNull);
    expect(matcher.suggestCategoryName('   '), isNull);
  });
}
