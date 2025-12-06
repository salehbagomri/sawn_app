import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for OCR (Optical Character Recognition) using Google ML Kit
/// Note: Arabic script is NOT supported by ML Kit on-device.
/// We use Latin script which works well for:
/// - Numbers (document numbers, dates, ID numbers)
/// - English text in Saudi documents
/// - Most official documents have bilingual text
class OcrService {
  // Singleton instance
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // Text recognizer for Latin script (includes numbers)
  TextRecognizer? _textRecognizer;

  /// Initialize the recognizer
  void _initRecognizer() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Extract text from image file
  /// Returns extracted text and detected fields
  Future<OcrResult> extractText(File imageFile) async {
    debugPrint('OcrService: Starting text extraction from ${imageFile.path}');

    try {
      _initRecognizer();

      final inputImage = InputImage.fromFile(imageFile);
      final result = await _textRecognizer!.processImage(inputImage);

      debugPrint('OcrService: Extracted ${result.text.length} characters');
      debugPrint('OcrService: Found ${result.blocks.length} text blocks');

      // Parse the text to extract fields
      final extractedFields = _parseDocumentFields(result.text);

      return OcrResult(
        fullText: result.text,
        extractedFields: extractedFields,
        textBlocks: result.blocks.map((b) => b.text).toList(),
      );
    } catch (e, stackTrace) {
      debugPrint('OcrService: Error extracting text: $e');
      debugPrint('OcrService: Stack trace: $stackTrace');
      return OcrResult.empty();
    }
  }

  /// Parse document fields from extracted text
  Map<String, String> _parseDocumentFields(String text) {
    final fields = <String, String>{};

    // Extract various fields
    final documentNumber = _extractDocumentNumber(text);
    final expiryDate = _extractExpiryDate(text);
    final issueDate = _extractIssueDate(text);
    final name = _extractName(text);
    final idNumber = _extractIdNumber(text);

    if (documentNumber != null) fields['documentNumber'] = documentNumber;
    if (expiryDate != null) fields['expiryDate'] = expiryDate;
    if (issueDate != null) fields['issueDate'] = issueDate;
    if (name != null) fields['name'] = name;
    if (idNumber != null) fields['idNumber'] = idNumber;

    return fields;
  }

  /// Extract document number patterns
  String? _extractDocumentNumber(String text) {
    // Pattern for document numbers (various formats)
    final patterns = [
      RegExp(r'(?:No\.?|Number|Reg\.?)\s*[:\s]*(\d{5,})', caseSensitive: false),
      RegExp(r'(\d{10,})', caseSensitive: false), // Long numbers are usually IDs
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract expiry date
  String? _extractExpiryDate(String text) {
    final patterns = [
      // Date patterns
      RegExp(r'(?:Expiry|Exp\.?|Valid\s*(?:until|to|thru))\s*[:\s]*(\d{1,4}[/\-\.]\d{1,2}[/\-\.]\d{1,4})', caseSensitive: false),
      // Hijri date (e.g., 1446/05/15)
      RegExp(r'(\d{4}[/\-]\d{2}[/\-]\d{2})', caseSensitive: false),
      // Common date format DD/MM/YYYY or YYYY/MM/DD
      RegExp(r'(\d{2}[/\-]\d{2}[/\-]\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract issue date
  String? _extractIssueDate(String text) {
    final patterns = [
      RegExp(r'(?:Issue\s*Date|Issued|Date\s*of\s*Issue)\s*[:\s]*(\d{1,4}[/\-\.]\d{1,2}[/\-\.]\d{1,4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract name
  String? _extractName(String text) {
    final patterns = [
      RegExp(r'(?:Name)\s*[:\s]*([A-Za-z\s]{3,})', caseSensitive: false),
      RegExp(r'(?:Holder|Owner)\s*[:\s]*([A-Za-z\s]{3,})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final name = match.group(1)!.trim();
        if (name.length > 2) {
          return name;
        }
      }
    }
    return null;
  }

  /// Extract Saudi ID number (10 digits starting with 1 or 2)
  String? _extractIdNumber(String text) {
    final pattern = RegExp(r'\b([12]\d{9})\b');
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  /// Dispose recognizer
  Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}

/// Result of OCR processing
class OcrResult {
  final String fullText;
  final Map<String, String> extractedFields;
  final List<String> textBlocks;

  const OcrResult({
    required this.fullText,
    required this.extractedFields,
    required this.textBlocks,
  });

  factory OcrResult.empty() {
    return const OcrResult(
      fullText: '',
      extractedFields: {},
      textBlocks: [],
    );
  }

  bool get isEmpty => fullText.isEmpty;
  bool get hasExtractedFields => extractedFields.isNotEmpty;

  /// Get specific field
  String? getField(String key) => extractedFields[key];

  /// Check if has document number
  bool get hasDocumentNumber => extractedFields.containsKey('documentNumber');

  /// Check if has expiry date
  bool get hasExpiryDate => extractedFields.containsKey('expiryDate');

  /// Check if has issue date
  bool get hasIssueDate => extractedFields.containsKey('issueDate');

  /// Check if has ID number
  bool get hasIdNumber => extractedFields.containsKey('idNumber');

  @override
  String toString() {
    return 'OcrResult(fullText: ${fullText.length} chars, fields: $extractedFields)';
  }
}
