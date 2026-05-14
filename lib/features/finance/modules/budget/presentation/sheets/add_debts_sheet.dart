import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import '../../../debt/domain/entities/debt.dart';
import '../../../finance_category/domain/entities/finance_category.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../controllers/budget_controller.dart';
import '../helpers/finance_category.dart';

class AddDebtSheet extends StatefulWidget {
  final bool isReceivable;
  final Future<void> Function(Debt debt, String? categoryId) onSave;

  const AddDebtSheet({
    super.key,
    required this.isReceivable,
    required this.onSave,
  });

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();

  late final SavingsController _savingsController;
  late final FinanceCategoryController _categoryController;
  late DebtType _type;
  String? _accountId;
  String? _categoryId;
  FinanceCategory? _selectedCategory;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savingsController = locator.get<SavingsController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _type = widget.isReceivable ? DebtType.lending : DebtType.borrowing;
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a person name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    // If one of account/category is filled, require both (they're needed together for the initial transaction)
    if ((_accountId != null) != (_categoryId != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select both account and category to record the initial transaction, or leave both empty to skip it.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final debt = Debt(
        type: _type,
        personName: name,
        description: _descCtrl.text.trim(),
        originalAmount: amount,
        remainingAmount: amount,
        startDate: DateTime.now(),
        dueDate: _dueDate,
        accountId: _accountId,
        monthlyPaymentAmount: double.tryParse(_monthlyCtrl.text) ?? 0,
      );
      await widget.onSave(debt, _categoryId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceivable = _type == DebtType.lending;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isReceivable ? 'Add Receivable' : 'Add Debt',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  SegmentedButton<DebtType>(
                    segments: const [
                      ButtonSegment(
                        value: DebtType.borrowing,
                        label: Text('Debt'),
                      ),
                      ButtonSegment(
                        value: DebtType.lending,
                        label: Text('Receivable'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _categoryId = null; // reset category when type changes
                    }),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Person name
              TextField(
                controller: _personCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isReceivable ? 'Borrower Name' : 'Lender Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                ),
              ),
              const SizedBox(height: 12),

              // Initial transaction (optional)
              Text(
                'Initial Transaction (optional)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isReceivable
                    ? 'Records money leaving your savings when you lend it.'
                    : 'Records money entering your savings when you borrow.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              AsyncStreamBuilder<List<SavingsBucket>>(
                state: _savingsController,
                builder: (_, buckets) => DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Savings Bucket (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— Skip —'),
                    ),
                    ...buckets.map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
                loadingBuilder: (_) => const LinearProgressIndicator(),
                errorBuilder: (_, m) => Text(m),
              ),
              const SizedBox(height: 12),

              // Category picker (grouped by budget)
              AsyncStreamBuilder<List<FinanceCategory>>(
                state: _categoryController,
                builder: (_, allCats) {
                  final budgetCtrl = locator.get<BudgetController>();
                  final allBudgets = budgetCtrl.data ?? [];
                  final targetType = isReceivable
                      ? CategoryType.expense
                      : CategoryType.income;
                  final groups = buildGroupedCategories(
                    allCategories: allCats,
                    allBudgets: allBudgets,
                    targetType: targetType,
                    monthKey:
                        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
                  );
                  return InkWell(
                    onTap: () async {
                      final picked = await showGroupedCategoryDialog(
                        context,
                        groups: groups,
                        selectedId: _categoryId,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedCategory = picked;
                          _categoryId = picked.id;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Category (optional)',
                        border: const OutlineInputBorder(),
                        helperText: isReceivable
                            ? 'Expense category — money lent out'
                            : 'Income category — money borrowed',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_selectedCategory != null) ...[
                            Icon(
                              _selectedCategory!.type.icon,
                              size: 16,
                              color: _selectedCategory!.type.color,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _selectedCategory?.name ?? '— Skip —',
                              style: TextStyle(
                                color: _selectedCategory == null
                                    ? AppColors.textTertiary
                                    : null,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.unfold_more,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (_) => const LinearProgressIndicator(),
                errorBuilder: (_, m) => Text(m),
              ),
              const SizedBox(height: 12),

              // Description (optional)
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Monthly payment (optional)
              TextField(
                controller: _monthlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly Payment (optional)',
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                  helperText: 'Fixed amount expected each month',
                ),
              ),
              const SizedBox(height: 12),

              // Due date (optional)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date (optional)'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, yyyy').format(_dueDate!)
                      : 'Not set',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isReceivable ? 'Add Receivable' : 'Add Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
