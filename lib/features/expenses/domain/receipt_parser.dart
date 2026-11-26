class ParsedReceipt {
  const ParsedReceipt({this.merchant, this.occurredAt, this.totalMinorUnits});

  final String? merchant;
  final DateTime? occurredAt;
  final int? totalMinorUnits;
}

class ReceiptParser {
  const ReceiptParser();

  static final _yearFirstDatePattern = RegExp(
    r'\b(\d{4})[./-](\d{1,2})[./-](\d{1,2})\b',
  );
  static final _dayFirstDatePattern = RegExp(
    r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b',
  );
  static final _amountPattern = RegExp(r'\d+(?:[., ]\d+)*');
  static final _metadataLinePattern = RegExp(
    r'^(TARIH|SAAT|FIS|FATURA|SUBE|KASA|KASIYER|MUSTERI|VERGI|VKN|TCKN|ADRES|TELEFON|TEL|BELGE|SIRA|NO)\b',
  );
  static final _addressLinePattern = RegExp(
    r'\b(MAH|MAHALLESI|SOK|SOKAK|CAD|CADDE|CADDESI|BULVAR|BLV|DAIRE|APT|NO)\b',
  );
  static final _productLinePattern = RegExp(r'\b(URUN|ADET|KILO|KG)\b');
  static final _businessNamePattern = RegExp(
    r'\b(ISLETME|TICARET|MARKET|MAGAZA|MAGAZALAR|LTD|STI)\b',
  );

  ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r\n?|\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return ParsedReceipt(
      merchant: _parseMerchant(lines),
      occurredAt: _parseDate(lines),
      totalMinorUnits: _parseTotal(lines),
    );
  }

  String? _parseMerchant(List<String> lines) {
    String? firstCandidate;
    String? businessNameCandidate;

    for (final line in lines) {
      final normalized = _normalize(line);
      if (!RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(line.toUpperCase()) ||
          _metadataLinePattern.hasMatch(normalized) ||
          _addressLinePattern.hasMatch(normalized) ||
          _productLinePattern.hasMatch(normalized) ||
          _totalPriority(line) > 0 ||
          normalized.contains('TOPLAM') ||
          normalized.startsWith('KDV') ||
          _containsDate(line)) {
        continue;
      }
      firstCandidate ??= line;
      if (_businessNamePattern.hasMatch(normalized)) {
        businessNameCandidate ??= line;
      }
    }
    return businessNameCandidate ?? firstCandidate;
  }

  DateTime? _parseDate(List<String> lines) {
    for (final line in lines) {
      final yearFirstMatch = _yearFirstDatePattern.firstMatch(line);
      if (yearFirstMatch != null) {
        final date = _makeDate(
          int.parse(yearFirstMatch.group(1)!),
          int.parse(yearFirstMatch.group(2)!),
          int.parse(yearFirstMatch.group(3)!),
        );
        if (date != null) return date;
      }

      final dayFirstMatch = _dayFirstDatePattern.firstMatch(line);
      if (dayFirstMatch != null) {
        var year = int.parse(dayFirstMatch.group(3)!);
        if (year < 100) year += 2000;
        final date = _makeDate(
          year,
          int.parse(dayFirstMatch.group(2)!),
          int.parse(dayFirstMatch.group(1)!),
        );
        if (date != null) return date;
      }
    }
    return null;
  }

  int? _parseTotal(List<String> lines) {
    var bestPriority = 0;
    int? bestTotal;

    for (var index = 0; index < lines.length; index++) {
      final priority = _totalPriority(lines[index]);
      if (priority == 0) continue;

      final total =
          _lastParsedAmount(_amountsIn(lines[index])) ??
          _lastParsedAmount(_amountsFollowing(lines, index));
      if (total != null && priority >= bestPriority) {
        bestPriority = priority;
        bestTotal = total;
      }
    }
    return bestTotal;
  }

  List<String> _amountsFollowing(List<String> lines, int index) {
    final monetaryAmounts = <String>[];
    for (var nextIndex = index + 1; nextIndex < lines.length; nextIndex++) {
      final line = lines[nextIndex];
      for (final amount in _amountsIn(line)) {
        if (RegExp(r'[,.]').hasMatch(amount) ||
            line.contains('₺') ||
            _normalize(line).contains('TL')) {
          monetaryAmounts.add(amount);
        }
      }
    }

    if (monetaryAmounts.isNotEmpty) return monetaryAmounts;
    if (index + 1 < lines.length) return _amountsIn(lines[index + 1]);
    return const [];
  }

  int? _lastParsedAmount(List<String> amounts) {
    for (final amount in amounts.reversed) {
      final parsedAmount = _parseAmountMinorUnits(amount);
      if (parsedAmount != null && parsedAmount > 0) return parsedAmount;
    }
    return null;
  }

  List<String> _amountsIn(String line) {
    return _amountPattern
        .allMatches(line)
        .map((match) => match.group(0)!)
        .toList(growable: false);
  }

  int _totalPriority(String line) {
    final normalized = _normalize(line);
    if (normalized.contains('ARA TOPLAM') ||
        normalized.contains('KDV TOPLAM') ||
        normalized.contains('TOPLAM KDV') ||
        normalized.contains('INDIRIM TOPLAM')) {
      return 0;
    }
    if (normalized.contains('GENEL TOPLAM') ||
        normalized.contains('TOPLAM ODENECEK') ||
        normalized.contains('ODENECEK')) {
      return 3;
    }
    if (normalized.contains('TOPLAM')) return 2;
    if (normalized.contains('TUTAR')) return 1;
    return 0;
  }

  bool _containsDate(String line) =>
      _yearFirstDatePattern.hasMatch(line) ||
      _dayFirstDatePattern.hasMatch(line);

  DateTime? _makeDate(int year, int month, int day) {
    if (year < 1900 || year > 2200) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String _normalize(String value) {
    return value
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ū', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }
}

int? _parseAmountMinorUnits(String input) {
  final normalized = input.replaceAll(' ', '');
  String wholeText;
  String fractionText = '';

  if (normalized.contains(',')) {
    if (normalized.indexOf(',') != normalized.lastIndexOf(',')) return null;
    final parts = normalized.split(',');
    if (parts.last.isEmpty || parts.last.length > 2) return null;
    wholeText = parts.first.replaceAll('.', '');
    fractionText = parts.last;
  } else if (normalized.contains('.')) {
    final parts = normalized.split('.');
    if (parts.any((part) => part.isEmpty)) return null;
    if (parts.length == 2 && parts.last.length <= 2) {
      wholeText = parts.first;
      fractionText = parts.last;
    } else if (parts.skip(1).every((part) => part.length == 3)) {
      wholeText = parts.join();
    } else {
      return null;
    }
  } else {
    wholeText = normalized;
  }

  if (!RegExp(r'^\d+$').hasMatch(wholeText) ||
      (fractionText.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionText))) {
    return null;
  }

  final wholeUnits = int.tryParse(wholeText);
  final minorUnits = int.tryParse(fractionText.padRight(2, '0')) ?? 0;
  if (wholeUnits == null ||
      wholeUnits > (0x7fffffffffffffff - minorUnits) ~/ 100) {
    return null;
  }
  return wholeUnits * 100 + minorUnits;
}
