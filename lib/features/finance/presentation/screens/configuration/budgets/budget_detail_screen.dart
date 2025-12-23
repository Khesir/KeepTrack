import 'package:flutter/material.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../../../../core/ui/scoped_screen.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/transaction/domain/entities/transaction.dart'
    as finance_transaction;
import '../../../../modules/budget/domain/repositories/budget_repository.dart';
import '../../../../modules/transaction/domain/repositories/transaction_repository.dart';

/// Budget detail screen - View and manage a specific budget
class BudgetDetailScreen extends ScopedScreen {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ScopedScreenState<BudgetDetailScreen> {
  late BudgetRepository _repository;
  late TransactionRepository _transactionRepository;
  late Budget _budget;
  List<finance_transaction.Transaction> _transactions = [];
  bool _isLoadingTransactions = false;

  // Calculate totals from transactions
  double get totalActualIncome {
    return _transactions
        .where((t) => t.type == finance_transaction.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalActualExpenses {
    return _transactions
        .where((t) => t.type == finance_transaction.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalActualIncome - totalActualExpenses;

  double getActualAmountForCategory(String categoryId) {
    return _transactions
        .where((t) => t.categoryId == categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  void registerServices() {
    // Uses global repository
  }

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _repository = getService<BudgetRepository>();
    _transactionRepository = getService<TransactionRepository>();
    _loadTransactions();
  }

  @override
  void onReady() {
    // Only UI configuration here (if needed)
  }

  Future<void> _loadTransactions() async {
    if (_budget.id == null) return;

    setState(() => _isLoadingTransactions = true);
    try {
      final transactions = await _transactionRepository.getTransactionsByBudget(
        _budget.id!,
      );
      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      setState(() => _isLoadingTransactions = false);
      // Silently fail
    }
  }

  Future<void> _refresh() async {
    if (_budget.id == null) return;

    try {
      final updated = await _repository.getBudgetById(_budget.id!);
      if (updated != null) {
        setState(() => _budget = updated);
        await _loadTransactions();
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _addRecord() async {
    if (_budget.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add transaction: Budget ID is missing'),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddRecordDialog(categories: _budget.categories),
    );

    if (result != null) {
      try {
        final transaction = finance_transaction.Transaction(
          budgetId: _budget.id!,
          categoryId: result['categoryId'],
          amount: result['amount'],
          description: result['description'],
          date: result['date'],
          type: result['type'],
        );

        await _transactionRepository.createTransaction(transaction);
        await _loadTransactions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding record: $e')));
        }
      }
    }
  }

  Future<void> _closeBudget() async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _ClosebudgetDialog(),
    );
    if (_budget.id == null) {
      throw Exception('Cannot update budget without an ID');
    }
    if (notes != null) {
      try {
        final closed = await _repository.closeBudget(_budget.id!, notes);
        setState(() => _budget = closed);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error closing budget: $e')));
        }
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (_budget.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget?\n\n'
          'This action cannot be undone. All records and data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteBudget(_budget.id!);
        if (mounted) {
          Navigator.pop(context); // Go back to list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting budget: $e')));
        }
      }
    }
  }

  Future<void> _reopenBudget() async {
    if (_budget.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reopen Budget'),
        content: const Text(
          'Are you sure you want to reopen this budget?\n\n'
          'The budget will become active again and you can add more records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reopened = await _repository.reopenBudget(_budget.id!);
        setState(() => _budget = reopened);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget reopened successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error reopening budget: $e')));
        }
      }
    }
  }

  bool _canReopenBudget() {
    // Can only reopen if:
    // 1. Budget is closed
    // 2. Budget month matches current month
    if (_budget.status != BudgetStatus.closed) return false;

    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return _budget.month == currentMonth;
  }

  @override
  Widget build(BuildContext context) {
    final budget = _budget;
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;
    final isActive = budget.status == BudgetStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget - ${budget.month}'),
        actions: [
          if (isActive)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeBudget,
              tooltip: 'Close Budget',
            ),
          if (_canReopenBudget())
            IconButton(
              icon: const Icon(Icons.lock_open),
              onPressed: _reopenBudget,
              tooltip: 'Reopen Budget',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteBudget,
            tooltip: 'Delete Budget',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card
            Card(
              color: balanceColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '₱${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                    Text(
                      balance >= 0 ? 'Surplus' : 'Deficit',
                      style: TextStyle(fontSize: 16, color: balanceColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryColumn(
                          'Income',
                          totalActualIncome,
                          budget.totalBudgetedIncome,
                          Colors.green,
                        ),
                        _buildSummaryColumn(
                          'Expenses',
                          totalActualExpenses,
                          budget.totalBudgetedExpenses,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Categories Breakdown
            const Text(
              'Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...budget.categories.map((category) {
              final actual = getActualAmountForCategory(category.id!);
              final percentage = category.targetAmount > 0
                  ? actual / category.targetAmount
                  : 0.0;

              return Card(
                child: ListTile(
                  title: Text(category.financeCategory?.name ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.financeCategory?.type.displayName ?? ''),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          percentage > 1.0 ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${actual.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'of ₱${category.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Records
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_transactions.length} records',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingTransactions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ..._transactions.reversed.map((transaction) {
                final category = budget.categories
                    .where((c) => c.id == transaction.categoryId)
                    .firstOrNull;
                final isIncome =
                    transaction.type ==
                    finance_transaction.TransactionType.income;

                return Card(
                  child: ListTile(
                    leading: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(category?.financeCategory?.name ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (transaction.description != null)
                          Text(transaction.description!),
                        Text(
                          '${transaction.date.month}/${transaction.date.day}/${transaction.date.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}₱${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              }),

            if (budget.notes != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(budget.notes!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: isActive
          ? FloatingActionButton(
              onPressed: _addRecord,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSummaryColumn(
    String label,
    double actual,
    double budgeted,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '₱${actual.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'of ₱${budgeted.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _AddRecordDialog extends StatefulWidget {
  final List categories;

  const _AddRecordDialog({required this.categories});

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  finance_transaction.TransactionType _selectedType =
      finance_transaction.TransactionType.expense;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: widget.categories
                  .map(
                    (cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategoryId = value as String?);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₱ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<finance_transaction.TransactionType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items:
                  [
                        finance_transaction.TransactionType.income,
                        finance_transaction.TransactionType.expense,
                      ]
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.name.substring(0, 1).toUpperCase() +
                                type.name.substring(1),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedCategoryId != null &&
                _amountController.text.isNotEmpty) {
              Navigator.pop(context, {
                'categoryId': _selectedCategoryId,
                'amount': double.tryParse(_amountController.text) ?? 0,
                'description': _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : null,
                'date': _selectedDate,
                'type': _selectedType,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ClosebudgetDialog extends StatefulWidget {
  @override
  State<_ClosebudgetDialog> createState() => _ClosebudgetDialogState();
}

class _ClosebudgetDialogState extends State<_ClosebudgetDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add notes about this budget period:'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _notesController.text.isNotEmpty ? _notesController.text : null,
            );
          },
          child: const Text('Close Budget'),
        ),
      ],
    );
  }
}
