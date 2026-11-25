class MerchantCategoryMatcher {
  const MerchantCategoryMatcher();

  static const _rules = [
    _MerchantCategoryRule('Market', [
      'migros',
      'a101',
      'bim',
      'sok',
      'carrefour',
      'macrocenter',
      'file market',
    ]),
    _MerchantCategoryRule('Yemek', [
      'restaurant',
      'restoran',
      'lokanta',
      'cafe',
      'starbucks',
      'mcdonald',
      'burger king',
      'kfc',
      'dominos',
      'yemeksepeti',
      'getir yemek',
    ]),
    _MerchantCategoryRule('Ulaşım', [
      'uber',
      'bitaksi',
      'taksi',
      'taxi',
      'istanbulkart',
      'izban',
      'opet',
      'shell',
      'petrol ofisi',
    ]),
    _MerchantCategoryRule('Faturalar', [
      'turkcell',
      'vodafone',
      'turk telekom',
      'enerjisa',
      'iski',
      'igdas',
      'elektrik',
      'dogalgaz',
    ]),
    _MerchantCategoryRule('Alışveriş', [
      'trendyol',
      'hepsiburada',
      'amazon',
      'n11',
      'zara',
      'lc waikiki',
      'boyner',
      'decathlon',
    ]),
    _MerchantCategoryRule('Sağlık', [
      'eczane',
      'pharmacy',
      'hastane',
      'acibadem',
      'medikal',
      'klinik',
      'clinic',
    ]),
    _MerchantCategoryRule('Eğlence', [
      'netflix',
      'spotify',
      'sinema',
      'cinema',
      'cinemaximum',
      'steam',
      'playstation',
      'youtube premium',
    ]),
  ];

  String? suggestCategoryName(String merchant) {
    final normalizedMerchant = _normalize(merchant);
    if (normalizedMerchant.isEmpty) return null;

    for (final rule in _rules) {
      if (rule.keywords.any(normalizedMerchant.contains)) {
        return rule.categoryName;
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value
        .replaceAll('İ', 'I')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('é', 'e');
  }
}

class _MerchantCategoryRule {
  const _MerchantCategoryRule(this.categoryName, this.keywords);

  final String categoryName;
  final List<String> keywords;
}
