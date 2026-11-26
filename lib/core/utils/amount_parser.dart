int? parseAmountMinorUnits(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  final parts = normalized.split('.');
  if (parts.length > 2) return null;

  final wholeText = parts.first.isEmpty ? '0' : parts.first;
  final fractionText = parts.length == 1 ? '' : parts.last;
  if (!RegExp(r'^\d+$').hasMatch(wholeText) ||
      (fractionText.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionText)) ||
      fractionText.length > 2) {
    return null;
  }

  final wholeUnits = int.tryParse(wholeText);
  final minorUnits = int.tryParse(fractionText.padRight(2, '0')) ?? 0;
  if (wholeUnits == null ||
      (wholeUnits == 0 && minorUnits == 0) ||
      wholeUnits > (0x7fffffffffffffff - minorUnits) ~/ 100) {
    return null;
  }

  return wholeUnits * 100 + minorUnits;
}

String formatAmountInput(int amountMinorUnits) {
  final wholeUnits = amountMinorUnits ~/ 100;
  final minorUnits = (amountMinorUnits % 100).toString().padLeft(2, '0');
  return '$wholeUnits,$minorUnits';
}
