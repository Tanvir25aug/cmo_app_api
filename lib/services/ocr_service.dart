import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService instance = OcrService._internal();
  OcrService._internal();

  TextRecognizer? _textRecognizer;
  bool _isInitialized = false;
  bool _isAvailable = true;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _isInitialized = true;
      _isAvailable = true;
    } catch (e) {
      _isAvailable = false;
      _isInitialized = true;
    }
  }

  Future<MeterOcrResult> extractMeterReading(String imagePath) async {
    try {
      await _initialize();

      if (!_isAvailable || _textRecognizer == null) {
        return MeterOcrResult(
          success: false,
          errorMessage: 'OCR not available on this device. Please enter values manually.',
        );
      }

      final inputImage = InputImage.fromFilePath(imagePath);

      RecognizedText recognizedText;
      try {
        recognizedText = await _textRecognizer!.processImage(inputImage);
      } on PlatformException {
        // Handle missing plugin gracefully
        _isAvailable = false;
        return MeterOcrResult(
          success: false,
          errorMessage: 'OCR service unavailable. Please enter values manually.',
        );
      }

      String? meterReading;
      String? meterNumber;
      String? onPeak;
      String? offPeak;
      String? kvar;

      final allText = recognizedText.text;
      final lines = <String>[];

      // Collect all text blocks
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          lines.add(line.text.trim());
        }
      }

      // Extract meter reading - look for numeric sequences (typically 5-8 digits)
      meterReading = _extractMeterReading(lines, allText);

      // Extract meter number - typically longer numeric or alphanumeric
      meterNumber = _extractMeterNumber(lines, allText);

      // Extract on-peak, off-peak, and kvar values
      final peakValues = _extractPeakValues(lines, allText);
      onPeak = peakValues['onPeak'];
      offPeak = peakValues['offPeak'];
      kvar = peakValues['kvar'];

      return MeterOcrResult(
        success: meterReading != null || meterNumber != null,
        meterReading: meterReading,
        meterNumber: meterNumber,
        onPeak: onPeak,
        offPeak: offPeak,
        kvar: kvar,
        rawText: allText,
        allLines: lines,
      );
    } on PlatformException {
      _isAvailable = false;
      return MeterOcrResult(
        success: false,
        errorMessage: 'OCR service unavailable. Please enter values manually.',
      );
    } catch (e) {
      return MeterOcrResult(
        success: false,
        errorMessage: 'OCR Error: ${e.toString()}',
      );
    }
  }

  String? _extractMeterReading(List<String> lines, String allText) {
    // First, look for lines containing keywords like "reading", "kwh", "total"
    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('kwh') ||
          lowerLine.contains('reading') ||
          lowerLine.contains('total') ||
          lowerLine.contains('import')) {
        final reading = _extractNumberFromLine(line);
        if (reading != null && reading.length >= 4) {
          return reading;
        }
      }
    }

    // Look for the largest numeric sequence (likely the main reading)
    final numericPattern = RegExp(r'\b(\d{4,8}(?:\.\d{1,2})?)\b');
    final matches = numericPattern.allMatches(allText).toList();

    if (matches.isNotEmpty) {
      matches.sort((a, b) => b.group(1)!.length.compareTo(a.group(1)!.length));

      for (var match in matches) {
        final value = match.group(1)!;
        final numValue = double.tryParse(value.replaceAll('.', ''));
        if (numValue != null && numValue > 0 && numValue < 99999999) {
          return value;
        }
      }
    }

    return null;
  }

  String? _extractMeterNumber(List<String> lines, String allText) {
    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('meter') &&
          (lowerLine.contains('no') || lowerLine.contains('number') || lowerLine.contains('#'))) {
        final number = _extractAlphanumericFromLine(line);
        if (number != null && number.length >= 6) {
          return number;
        }
      }
      if (lowerLine.contains('serial') || lowerLine.contains('s/n')) {
        final number = _extractAlphanumericFromLine(line);
        if (number != null && number.length >= 6) {
          return number;
        }
      }
    }

    final meterPattern = RegExp(r'\b([A-Z0-9]{8,14})\b', caseSensitive: false);
    final matches = meterPattern.allMatches(allText).toList();

    for (var match in matches) {
      final value = match.group(1)!;
      if (RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value)) {
        return value.toUpperCase();
      }
    }

    return null;
  }

  Map<String, String?> _extractPeakValues(List<String> lines, String allText) {
    String? onPeak;
    String? offPeak;
    String? kvar;

    for (String line in lines) {
      final lowerLine = line.toLowerCase();

      if (lowerLine.contains('on-peak') ||
          lowerLine.contains('onpeak') ||
          lowerLine.contains('on peak') ||
          lowerLine.contains('peak 1')) {
        onPeak = _extractNumberFromLine(line);
      }

      if (lowerLine.contains('off-peak') ||
          lowerLine.contains('offpeak') ||
          lowerLine.contains('off peak') ||
          lowerLine.contains('peak 2')) {
        offPeak = _extractNumberFromLine(line);
      }

      if (lowerLine.contains('kvar') ||
          lowerLine.contains('reactive') ||
          lowerLine.contains('kvarh')) {
        kvar = _extractNumberFromLine(line);
      }
    }

    return {
      'onPeak': onPeak,
      'offPeak': offPeak,
      'kvar': kvar,
    };
  }

  String? _extractNumberFromLine(String line) {
    final pattern = RegExp(r'(\d+(?:\.\d+)?)');
    final matches = pattern.allMatches(line).toList();

    if (matches.isNotEmpty) {
      matches.sort((a, b) => b.group(1)!.length.compareTo(a.group(1)!.length));
      return matches.first.group(1);
    }
    return null;
  }

  String? _extractAlphanumericFromLine(String line) {
    final pattern = RegExp(r'[:\s]([A-Z0-9]{6,14})', caseSensitive: false);
    final match = pattern.firstMatch(line);
    if (match != null) {
      return match.group(1)?.toUpperCase();
    }

    final altPattern = RegExp(r'\b([A-Z0-9]{6,14})\b', caseSensitive: false);
    final altMatches = altPattern.allMatches(line).toList();

    for (var m in altMatches) {
      final value = m.group(1)!;
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        return value.toUpperCase();
      }
    }

    return null;
  }

  /// Extract seal numbers from image
  Future<SealOcrResult> extractSealNumber(String imagePath) async {
    try {
      await _initialize();

      if (!_isAvailable || _textRecognizer == null) {
        return SealOcrResult(
          success: false,
          errorMessage: 'OCR not available. Please enter seal number manually.',
        );
      }

      final inputImage = InputImage.fromFilePath(imagePath);

      RecognizedText recognizedText;
      try {
        recognizedText = await _textRecognizer!.processImage(inputImage);
      } on PlatformException {
        _isAvailable = false;
        return SealOcrResult(
          success: false,
          errorMessage: 'OCR service unavailable. Please enter seal number manually.',
        );
      }

      final allText = recognizedText.text;
      final lines = <String>[];

      // Collect all text blocks
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          lines.add(line.text.trim());
        }
      }

      // Extract seal numbers - typically alphanumeric codes
      final sealNumbers = _extractSealNumbers(lines, allText);

      return SealOcrResult(
        success: sealNumbers.isNotEmpty,
        sealNumbers: sealNumbers,
        rawText: allText,
        allLines: lines,
      );
    } on PlatformException {
      _isAvailable = false;
      return SealOcrResult(
        success: false,
        errorMessage: 'OCR service unavailable. Please enter seal number manually.',
      );
    } catch (e) {
      return SealOcrResult(
        success: false,
        errorMessage: 'OCR Error: ${e.toString()}',
      );
    }
  }

  List<String> _extractSealNumbers(List<String> lines, String allText) {
    final sealNumbers = <String>[];

    // Look for alphanumeric sequences that could be seal numbers
    // Seal numbers are typically 6-15 characters, mix of letters and numbers
    final sealPattern = RegExp(r'\b([A-Z0-9]{4,15})\b', caseSensitive: false);
    final matches = sealPattern.allMatches(allText).toList();

    for (var match in matches) {
      final value = match.group(1)!.toUpperCase();
      // Filter out common words and ensure it's likely a seal number
      if (value.length >= 4 &&
          !_isCommonWord(value) &&
          (RegExp(r'[A-Za-z]').hasMatch(value) || RegExp(r'\d').hasMatch(value))) {
        if (!sealNumbers.contains(value)) {
          sealNumbers.add(value);
        }
      }
    }

    // Also check each line for potential seal numbers
    for (String line in lines) {
      final cleanLine = line.trim().toUpperCase();
      if (cleanLine.length >= 4 &&
          cleanLine.length <= 15 &&
          !_isCommonWord(cleanLine) &&
          RegExp(r'^[A-Z0-9]+$').hasMatch(cleanLine)) {
        if (!sealNumbers.contains(cleanLine)) {
          sealNumbers.add(cleanLine);
        }
      }
    }

    return sealNumbers;
  }

  bool _isCommonWord(String text) {
    final commonWords = [
      'SEAL', 'NUMBER', 'METER', 'COVER', 'BATTERY', 'TERMINAL',
      'TYPE', 'SERIAL', 'MODEL', 'DATE', 'TIME', 'MADE', 'CHINA',
      'WARNING', 'DANGER', 'POWER', 'ENERGY', 'KWH', 'VOLT', 'AMP',
    ];
    return commonWords.contains(text.toUpperCase());
  }

  void dispose() {
    _textRecognizer?.close();
  }
}

class SealOcrResult {
  final bool success;
  final List<String>? sealNumbers;
  final String? rawText;
  final List<String>? allLines;
  final String? errorMessage;

  SealOcrResult({
    required this.success,
    this.sealNumbers,
    this.rawText,
    this.allLines,
    this.errorMessage,
  });
}

class MeterOcrResult {
  final bool success;
  final String? meterReading;
  final String? meterNumber;
  final String? onPeak;
  final String? offPeak;
  final String? kvar;
  final String? rawText;
  final List<String>? allLines;
  final String? errorMessage;

  MeterOcrResult({
    required this.success,
    this.meterReading,
    this.meterNumber,
    this.onPeak,
    this.offPeak,
    this.kvar,
    this.rawText,
    this.allLines,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'MeterOcrResult(success: $success, reading: $meterReading, number: $meterNumber, onPeak: $onPeak, offPeak: $offPeak, kvar: $kvar)';
  }
}
