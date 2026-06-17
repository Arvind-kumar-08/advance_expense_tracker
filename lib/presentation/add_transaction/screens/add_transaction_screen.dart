import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/transaction_model.dart';
import '../../../state/providers/transaction_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/amount_input.dart';

/// Screen for adding or editing a transaction
class AddTransactionScreen extends StatefulWidget {
  final String? transactionId; // If provided, edit mode

  const AddTransactionScreen({
    super.key,
    this.transactionId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _receiptDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTransactionData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_receiptDataLoaded && widget.transactionId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map) {
        _amountController.text = args['amount']?.toString() ?? '';
        _noteController.text = args['title']?.toString() ?? '';
        _selectedCategory = args['category']?.toString();
        _selectedDate = args['date'] is DateTime ? args['date'] : DateTime.now();
        _selectedType = TransactionType.expense;

        _receiptDataLoaded = true;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Load transaction data if in edit mode
  Future<void> _loadTransactionData() async {
    if (widget.transactionId == null) return;

    final transactionProvider = context.read<TransactionProvider>();
    final transaction =
    await transactionProvider.getTransactionById(widget.transactionId!);

    if (! mounted || transaction ==null ) return;  {
      setState(() {
        _amountController.text = transaction.amount.toString();
        _noteController.text = transaction.note ?? '';
        _selectedType = transaction.type;
        _selectedCategory = transaction.category;
        _selectedDate = transaction.date;
      });
    }
  }

  /// Load data coming from receipt scanner
  void _loadReceiptData() {
    if (_receiptDataLoaded || widget.transactionId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final amount = args['amount'];
      final category = args['category'];
      final title = args['title'];
      final date = args['date'];

      setState(() {
        if (amount != null) {
          _amountController.text = amount.toString();
        }

        if (category != null && category.toString().trim().isNotEmpty) {
          _selectedCategory = category.toString();
        }

        if (title != null && title.toString().trim().isNotEmpty) {
          _noteController.text = title.toString();
        }

        if (date is DateTime) {
          _selectedDate = date;
        }

        _selectedType = TransactionType.expense;
        _receiptDataLoaded = true;
      });
    }
  }
  /// Handle save transaction
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final transactionProvider = context.read<TransactionProvider>();
    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    bool success;

    if (widget.transactionId == null) {
      // Add new transaction
      success = await transactionProvider.addTransaction(
        amount: amount,
        category: _selectedCategory!,
        type: _selectedType,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      );
    } else {
      // Update existing transaction
      success = await transactionProvider.updateTransaction(
        id: widget.transactionId!,
        amount: amount,
        category: _selectedCategory!,
        type: _selectedType,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionId == null
                ? AppStrings.transactionAdded
                : AppStrings.transactionUpdated,
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transactionProvider.errorMessage ?? 'Failed to save transaction',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show date picker
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceiptData();
    });

    final isEditMode = widget.transactionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? AppStrings.editTransaction
              : AppStrings.addTransaction,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Selector
              _buildTypeSelector(theme),
              const SizedBox(height: 24),

              // Amount Input
              AmountInput(
                controller: _amountController,
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 24),

              // Category Selector
              CategorySelector(
                selectedCategory: _selectedCategory,
                transactionType: _selectedType,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Date Selector
              _buildDateSelector(theme),
              const SizedBox(height: 24),

              // Note Input
              CustomTextField(
                label: AppStrings.note,
                hint: AppStrings.addNote,
                controller: _noteController,
                maxLines: 3,
                prefixIcon: Icons.note_outlined,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: AppStrings.save,
                onPressed: _handleSave,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build transaction type selector (Income/Expense)
  Widget _buildTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.transactionType,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                label: AppStrings.income,
                type: TransactionType.income,
                icon: Icons.arrow_upward,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                label: AppStrings.expense,
                type: TransactionType.expense,
                icon: Icons.arrow_downward,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual type button
  Widget _buildTypeButton({
    required String label,
    required TransactionType type,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedType == type;
    final color = type == TransactionType.income
        ? Colors.green
        : Colors.red;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = null; // Reset category when type changes
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.iconTheme.color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build date selector
  Widget _buildDateSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.date,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormatter.formatDateLong(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}