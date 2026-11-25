import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/receipt_scan_result.dart';

abstract interface class ReceiptOcrService {
  Future<ReceiptScanResult?> scan(ReceiptImageSource source);

  Future<String> persistImage(String imagePath);
}

class MobileReceiptOcrService implements ReceiptOcrService {
  MobileReceiptOcrService({
    ImagePicker? imagePicker,
    TextRecognizer? textRecognizer,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _textRecognizer =
           textRecognizer ??
           TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _imagePicker;
  final TextRecognizer _textRecognizer;

  @override
  Future<ReceiptScanResult?> scan(ReceiptImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source == ReceiptImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (image == null) return null;

    final recognizedText = await _textRecognizer.processImage(
      InputImage.fromFilePath(image.path),
    );

    return ReceiptScanResult(
      imagePath: image.path,
      rawText: recognizedText.text,
    );
  }

  @override
  Future<String> persistImage(String imagePath) async {
    final sourceImage = File(imagePath);
    final fileName = sourceImage.uri.pathSegments.last;
    final supportDirectory = await getApplicationSupportDirectory();
    final extension = _safeExtension(fileName);
    final destinationPath =
        '${supportDirectory.path}${Platform.pathSeparator}'
        'receipt-${Uuid().v4()}$extension';
    final storedImage = await sourceImage.copy(destinationPath);
    return storedImage.path;
  }

  Future<void> dispose() => _textRecognizer.close();

  String _safeExtension(String fileName) {
    final extensionStart = fileName.lastIndexOf('.');
    if (extensionStart == -1) return '';

    final extension = fileName.substring(extensionStart).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension) ? extension : '';
  }
}
