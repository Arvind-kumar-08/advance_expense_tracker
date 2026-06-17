class ParsedReceiptData {
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  ParsedReceiptData({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}

class ReceiptParserService {
  ParsedReceiptData parseReceiptText(String text) {
    final cleanedText = text.trim();
    final lines = cleanedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final title = _extractMerchantName(lines);
    final amount = _extractTotalAmount(lines);
    final category = _detectCategory(cleanedText);

    return ParsedReceiptData(
      title: title,
      amount: amount,
      category: category,
      date: DateTime.now(),
    );
  }

  String _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return 'Receipt Expense';

    final ignoredWords = [
      'tax invoice',
      'invoice',
      'receipt',
      'bill',
      'cash memo',
      'gst',
      'phone',
      'mobile',
      'address',
    ];

    for (final line in lines.take(6)) {
      final lowerLine = line.toLowerCase();

      final shouldIgnore = ignoredWords.any(
            (word) => lowerLine.contains(word),
      );

      final hasNumber = RegExp(r'\d').hasMatch(line);

      if (!shouldIgnore && !hasNumber && line.length >= 3) {
        return _cleanTitle(line);
      }
    }

    return _cleanTitle(lines.first);
  }

  double _extractTotalAmount(List<String> lines) {
    final amountRegex = RegExp(r'(\d{1,6}[,.]?\d{0,2})');

    final priorityKeywords = [
      'grand total',
      'net amount',
      'net total',
      'amount payable',
      'total amount',
      'total payable',
      'bill amount',
      'balance due',
      'total',
    ];

    for (final keyword in priorityKeywords) {
      for (final line in lines.reversed) {
        final lowerLine = line.toLowerCase();

        if (lowerLine.contains(keyword)) {
          final matches = amountRegex.allMatches(line).toList();

          if (matches.isNotEmpty) {
            final value = matches.last.group(0) ?? '0';
            final amount = _parseAmount(value);

            if (amount > 0) return amount;
          }
        }
      }
    }

    final possibleAmounts = <double>[];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      if (lowerLine.contains('gst') ||
          lowerLine.contains('tax') ||
          lowerLine.contains('qty') ||
          lowerLine.contains('cgst') ||
          lowerLine.contains('sgst') ||
          lowerLine.contains('invoice') ||
          lowerLine.contains('phone') ||
          lowerLine.contains('mobile')) {
        continue;
      }

      final matches = amountRegex.allMatches(line);

      for (final match in matches) {
        final amount = _parseAmount(match.group(0) ?? '0');

        if (amount >= 10 && amount <= 100000) {
          possibleAmounts.add(amount);
        }
      }
    }

    if (possibleAmounts.isEmpty) return 0;

    possibleAmounts.sort();

    return possibleAmounts.last;
  }

  String _detectCategory(String text) {
    final lowerText = text.toLowerCase();

    // Food
    if (_containsAny(lowerText, [
      'zomato',
      'swiggy',
      'restaurant',
      'cafe',
      'pizza',
      'burger',
      'food',
      'tea',
      'coffee',
    ])) {
      return 'Food';
    }

    // Shopping (includes grocery stores)
    if (_containsAny(lowerText, [
      'dmart',
      'd-mart',
      'big bazaar',
      'reliance fresh',
      'grocery',
      'supermarket',
      'mart',
      'amazon',
      'flipkart',
      'myntra',
      'store',
      'shopping',
    ])) {
      return 'Shopping';
    }

    // Travel
    if (_containsAny(lowerText, [
      'uber',
      'ola',
      'rapido',
      'metro',
      'railway',
      'irctc',
      'bus',
      'taxi',
      'fuel',
      'petrol',
      'diesel',
    ])) {
      return 'Travel';
    }

    // Healthcare
    if (_containsAny(lowerText, [
      'pharmacy',
      'medical',
      'medicine',
      'apollo',
      'hospital',
      'clinic',
      'doctor',
    ])) {
      return 'Healthcare';
    }

    // Utilities
    if (_containsAny(lowerText, [
      'electricity',
      'water bill',
      'gas bill',
      'wifi',
      'broadband',
      'internet',
      'mobile recharge',
      'postpaid',
      'prepaid',
    ])) {
      return 'Utilities';
    }

    // Education
    if (_containsAny(lowerText, [
      'course',
      'udemy',
      'coursera',
      'book',
      'tuition',
      'school',
      'college',
    ])) {
      return 'Education';
    }

    // Entertainment
    if (_containsAny(lowerText, [
      'netflix',
      'spotify',
      'movie',
      'cinema',
      'prime video',
      'hotstar',
      'game',
    ])) {
      return 'Entertainment';
    }

    return 'Other';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  double _parseAmount(String value) {
    final cleaned = value
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll('Rs', '')
        .replaceAll('rs', '')
        .trim();

    return double.tryParse(cleaned) ?? 0;
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s&.-]'), '')
        .trim();
  }
}