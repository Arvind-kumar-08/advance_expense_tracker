import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../data/models/transaction_model.dart';
import '../../../state/providers/receipt_provider.dart';
import '../../../state/providers/transaction_provider.dart';

class ReceiptScannerScreen extends StatelessWidget {
  const ReceiptScannerScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final imagePicker = ImagePicker();

    final pickedFile = await imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    if (!context.mounted) return;

    await context.read<ReceiptProvider>().processReceipt(pickedFile.path);
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final receiptProvider = context.watch<ReceiptProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (receiptProvider.selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  receiptProvider.selectedImage!,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_long,
                    size: 72,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: receiptProvider.isLoading
                  ? null
                  : () => _showImageSourceSheet(context),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Receipt'),
            ),

            const SizedBox(height: 24),

            if (receiptProvider.errorMessage != null)
              Text(
                receiptProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            Text(
              'Extracted Text',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5),
                ),
              ),
              child: receiptProvider.isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
                  : Text(
                receiptProvider.extractedText.isEmpty
                    ? 'No receipt scanned yet.'
                    : receiptProvider.extractedText,
              ),
            ),

            if (receiptProvider.parsedData != null) ...[
              const SizedBox(height: 24),

              Text(
                'Detected Expense',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _resultRow(
                        'Title',
                        receiptProvider.parsedData!.title,
                      ),
                      _resultRow(
                        'Amount',
                        '₹${receiptProvider.parsedData!.amount.toStringAsFixed(2)}',
                      ),
                      _resultRow(
                        'Category',
                        receiptProvider.parsedData!.category,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: receiptProvider.parsedData == null
                    ? null
                    : () async {
                  final data = receiptProvider.parsedData!;

                  final success =
                  await context.read<TransactionProvider>().addTransaction(
                    amount: data.amount,
                    category: data.category,
                    type: TransactionType.expense,
                    date: data.date,
                    note: data.title,
                  );
                  if (success) {
                    receiptProvider.clearReceipt();
                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                          (route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense added from receipt'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add expense'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Use This Expense'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}