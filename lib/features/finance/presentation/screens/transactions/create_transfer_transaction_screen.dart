import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
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
  bool _showFeeFields = false;

  @override
  void initState() {
    super.initState();
    _transactionController = locator.get<TransactionController>();
    _accountController = locator.get<AccountController>();
    _categoryController = locator.get<FinanceCategoryController>();
    supabaseService = locator.get<SupabaseService>();

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
    if (!_formKey.currentState!.validate()) return;

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

    setState(() => _isCreating = true);

    try {
      final feeAmount = _feeController.text.trim().isEmpty
          ? 0.0
          : double.parse(_feeController.text);

      final transaction = Transaction(
        accountId: _fromAccountId,
        toAccountId: _toAccountId,
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
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(colorScheme, theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildFromAccountSelector(colorScheme),
                  const SizedBox(height: 12),
                  _buildToAccountSelector(colorScheme),
                  const SizedBox(height: 12),
                  _buildDateRow(theme, colorScheme),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      counterText: '',
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 12),
                  _buildFeeSection(colorScheme, theme),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      counterText: '',
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),
                  _buildCategorySelector(colorScheme, theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _createTransfer,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isCreating ? 'Creating...' : 'Create Transfer'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward, size: 16),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward, size: 16),
              ),
              ButtonSegment(
                value: TransactionType.transfer,
                label: Text('Transfer'),
                icon: Icon(Icons.swap_horiz, size: 16),
              ),
            ],
            selected: const {TransactionType.transfer},
            onSelectionChanged: (selection) {
              final type = selection.first;
              if (type != TransactionType.transfer) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.transactionCreate,
                  arguments: {'initialType': type},
                );
              }
            },
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencyFormatter.currencySymbol,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _amountController,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.outlineVariant,
                      fontWeight: FontWeight.w300,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFromAccountSelector(ColorScheme colorScheme) {
    return AsyncStreamBuilder<List<Account>>(
      state: _accountController,
      loadingBuilder: (context) => const LinearProgressIndicator(),
      errorBuilder: (context, message) => Text(
        'Error loading accounts: $message',
        style: TextStyle(color: colorScheme.error),
      ),
      builder: (context, accounts) {
        if (accounts.isEmpty) {
          return Text(
            'No accounts found. Please create at least two accounts.',
            style: TextStyle(color: colorScheme.error),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _fromAccountId != null &&
                  accounts.any((a) => a.id == _fromAccountId)
              ? _fromAccountId
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'From Account',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          items: accounts
              .map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currencyFormatter.currencySymbol}${NumberFormat('#,##0.00').format(a.balance)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: a.balance >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _fromAccountId = value),
          validator: (value) =>
              value == null ? 'Please select source account' : null,
          menuMaxHeight: 300,
        );
      },
    );
  }

  Widget _buildToAccountSelector(ColorScheme colorScheme) {
    return AsyncStreamBuilder<List<Account>>(
      state: _accountController,
      loadingBuilder: (context) => const LinearProgressIndicator(),
      errorBuilder: (context, message) => const SizedBox.shrink(),
      builder: (context, accounts) {
        return DropdownButtonFormField<String>(
          initialValue: _toAccountId != null &&
                  accounts.any((a) => a.id == _toAccountId)
              ? _toAccountId
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'To Account',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            prefixIcon: const Icon(Icons.account_balance_outlined),
          ),
          items: accounts
              .map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currencyFormatter.currencySymbol}${NumberFormat('#,##0.00').format(a.balance)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: a.balance >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _toAccountId = value),
          validator: (value) =>
              value == null ? 'Please select destination account' : null,
          menuMaxHeight: 300,
        );
      },
    );
  }

  Widget _buildDateRow(ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEE, MMM d y  •  h:mm a').format(_selectedDate),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection(ColorScheme colorScheme, ThemeData theme) {
    final hasFee = _feeController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showFeeFields = !_showFeeFields),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasFee
                        ? 'Fee: ${currencyFormatter.currencySymbol}${_feeController.text}'
                        : 'Add Transfer Fee (Optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasFee
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  _showFeeFields ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_showFeeFields) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _feeController,
            decoration: InputDecoration(
              labelText: 'Fee Amount',
              hintText: 'e.g., 15.00',
              prefixText: '${currencyFormatter.currencySymbol} ',
              helperText: 'Deducted from source account',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) return 'Invalid fee amount';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector(ColorScheme colorScheme, ThemeData theme) {
    return AsyncStreamBuilder<List<FinanceCategory>>(
      state: _categoryController,
      loadingBuilder: (context) => const SizedBox.shrink(),
      errorBuilder: (context, message) => const SizedBox.shrink(),
      builder: (context, categories) {
        final transferCategories =
            categories.where((c) => c.type == CategoryType.transfer).toList();

        if (transferCategories.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<String>(
          initialValue: _transferCategoryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Category (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('None')),
            ...transferCategories.map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (value) => setState(() => _transferCategoryId = value),
          menuMaxHeight: 300,
        );
      },
    );
  }
}
