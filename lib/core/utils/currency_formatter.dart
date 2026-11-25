String formatTryMinorUnits(int amountMinorUnits) {
  final wholeUnits = amountMinorUnits ~/ 100;
  final minorUnits = (amountMinorUnits % 100).toString().padLeft(2, '0');
  return '₺$wholeUnits,$minorUnits';
}
