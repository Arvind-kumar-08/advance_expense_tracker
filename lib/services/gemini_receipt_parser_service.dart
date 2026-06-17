import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'receipt_parser_service.dart';

class GeminiReceiptParserService {
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );

  Future<ParsedReceiptData> parseReceiptText(String receiptText) async {
    final prompt = '''
You are an expense receipt parser.

Extract only these fields from the OCR receipt text:
- title: merchant/store name
- amount: final payable amount only
- category: one of Food, Travel, Rent, Shopping, Entertainment, Healthcare, Education, Utilities, Other
- date: receipt date in yyyy-MM-dd format. If not found, use today's date.

Important rules:
- Do not use GST number, phone number, invoice number, bill number, item quantity, tax amount, or card number as amount.
- Amount must be final payable/total amount.
- Return JSON only. No markdown. No explanation.

OCR Text:
$receiptText

JSON format:
{
  "title": "Merchant Name",
  "amount": 0.0,
  "category": "Other",
  "date": "2026-06-18"
}
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    final text = response.text ?? '';

    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final Map<String, dynamic> data = jsonDecode(cleaned);

    return ParsedReceiptData(
      title: data['title']?.toString() ?? 'Receipt Expense',
      amount: double.tryParse(data['amount'].toString()) ?? 0,
      category: data['category']?.toString() ?? 'Other',
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}