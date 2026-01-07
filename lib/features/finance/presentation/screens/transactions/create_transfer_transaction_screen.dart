import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../modules/account/domain/entities/account.dart';
import '../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../modules/transaction/domain/entities/transaction.dart';
import '../../state/account_controller.dart';
import '../../state/finance_category_controller.dart';
import '../../state/transaction_controller.dart';

/// Screen for creating a transfer transaction between accounts
class CreateTransferTransactionScreen extends StatefulWidget {
  const CreateTransferTransactionScreen({super.key});

  @override
  State<CreateTransferTransactionScreen> createState() =>
      _CreateTransferTransactionScreenState();
}

class _CreateTransferTransactionScreenState
    extends State<CreateTransferTransactionScreen> {
  late final TransactionController _transactionController;
  late final AccountController _accountController;
  late final FinanceCategoryController _categoryController;
  late final SupabaseService supabaseService;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;
  String? _transferCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _transactionController = locator.get<TransactionController>();
    _accountController = locator.get<AccountController>();
    _categoryController = locator.get<FinanceCategoryController>();
    supabaseService = locator.get<SupabaseService>();

    // Load accounts and categories
    _accountController.loadAccounts();
    _categoryController.loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
        });
      }
    }
  }

  Future<void> _createTransfer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fromAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select source account')),
      );
      return;
    }

    if (_toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination account')),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination accounts must be different'),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final feeAmount = _feeController.text.trim().isEmpty
          ? 0.0
          : double.parse(_feeController.text);

      final transaction = Transaction(
        accountId: _fromAccountId, // Source account
        toAccountId: _toAccountId, // Destination account
        financeCategoryId: _transferCategoryId,
        amount: double.parse(_amountController.text),
        type: TransactionType.transfer,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        fee: feeAmount,
        userId: supabaseService.userId,
      );

      await _transactionController.createTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer created successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create transfer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Between Accounts'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Move money between your accounts. Source account pays amount + fee, destination receives amount only.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fee Field (Optional)
            TextFormField(
              controller: _feeController,
              decoration: InputDecoration(
                labelText: 'Transfer Fee (Optional)',
                hintText: 'e.g., 15.00 for bank transfer fee',
                prefixText: '₱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                helperText: 'Fee is deducted from source account',
                helperMaxLines: 2,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid fee amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // From Account Selector
            AsyncStreamBuilder<List<Account>>(
              state: _accountController,
              loadingBuilder: (context) => const LinearProgressIndicator(),
              errorBuilder: (context, message) => Card(
                color: Colors.red.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading accounts: $message',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              builder: (context, accounts) {
                if (accounts.isEmpty) {
                  return Card(
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No accounts found. Please create at least two accounts.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _fromAccountId,
                  decoration: InputDecoration(
                    labelText: 'From Account (Source)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                  ),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  account.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${currencyFormatter.currencySymbol}${NumberFormat('#,##0.00').format(account.balance)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: account.balance >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _fromAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select source account';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // To Account Selector
            AsyncStreamBuilder<List<Account>>(
              state: _accountController,
              loadingBuilder: (context) => const LinearProgressIndicator(),
              errorBuilder: (context, message) => const SizedBox.shrink(),
              builder: (context, accounts) {
                return DropdownButtonFormField<String>(
                  value: _toAccountId,
                  decoration: InputDecoration(
                    labelText: 'To Account (Destination)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  account.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${currencyFormatter.currencySymbol}${NumberFormat('#,##0.00').format(account.balance)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: account.balance >= 0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _toAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select destination account';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Transfer Category Selector (Optional)
            AsyncStreamBuilder<List<FinanceCategory>>(
              state: _categoryController,
              loadingBuilder: (context) => const SizedBox.shrink(),
              errorBuilder: (context, message) => const SizedBox.shrink(),
              builder: (context, categories) {
                final transferCategories = categories
                    .where((c) => c.type == CategoryType.transfer)
                    .toList();

                if (transferCategories.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _transferCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...transferCategories.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _transferCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Date & Time Selector
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Monthly savings transfer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 24),

            // Create Button
            FilledButton.icon(
              onPressed: _isCreating ? null : _createTransfer,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(_isCreating ? 'Creating...' : 'Create Transfer'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
