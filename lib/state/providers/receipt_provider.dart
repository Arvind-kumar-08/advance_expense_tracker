import 'dart:io';

import 'package:flutter/foundation.dart';
import '';
import '../../services/gemini_receipt_parser_service.dart';
import '../../services/receipt_parser_service.dart';
import '../../services/reciept_ocr_service.dart';

class ReceiptProvider with ChangeNotifier {
  final ReceiptOcrService _ocrService = ReceiptOcrService();

  final GeminiReceiptParserService _geminiParserService =
  GeminiReceiptParserService();

  File? _selectedImage;
  String _extractedText = '';
  ParsedReceiptData? _parsedData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  File? get selectedImage => _selectedImage;

  String get extractedText => _extractedText;

  ParsedReceiptData? get parsedData => _parsedData;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> processReceipt(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedImage = File(imagePath);
    _extractedText = '';
    _parsedData = null;

    notifyListeners();

    try {
      final extractedText = await _ocrService.extractText(
        imagePath,
      );

      _extractedText = extractedText;

      if (extractedText.trim().isNotEmpty) {
        try {
          _parsedData = await _geminiParserService.parseReceiptText(
            extractedText,
          );
        } catch (_) {
          _parsedData = await _geminiParserService.parseReceiptText(
            extractedText,
          );
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to scan receipt: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearReceipt() {
    _selectedImage = null;
    _extractedText = '';
    _parsedData = null;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}