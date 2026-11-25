enum ReceiptImageSource { camera, gallery }

class ReceiptScanResult {
  const ReceiptScanResult({required this.imagePath, required this.rawText});

  final String imagePath;
  final String rawText;
}
