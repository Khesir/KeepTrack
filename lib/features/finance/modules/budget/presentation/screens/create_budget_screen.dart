import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../controllers/budget_controller.dart';
import '../../../../presentation/state/finance_category_controller.dart';
import '../dialogs/budget_category_dialog.dart';
import '../helpers/month_formatter.dart';
import '../widgets/budget_form_widgets.dart';

class CreateBudgetScreen extends ScopedScreen {
  final Budget? existingBudget;
  final String? initialMonth;

  const CreateBudgetScreen({super.key, this.existingBudget, this.initialMonth});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ScopedScreenState<CreateBudgetScreen> {
  late final BudgetController _controller;
  late final FinanceCategoryController _categoryController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _customTargetController = TextEditingController();
  final List<BudgetCategory> _categories = [];
  bool _isCreating = false;
  String _selectedMonth = '';
  BudgetType _budgetType = BudgetType.expense;
  BudgetPeriodType _periodType = BudgetPeriodType.monthly;
  bool _copyFromBudget = false;
  String? _sourceBudgetId;
  bool _useCustomTarget = false;

  bool get _isEditing => widget.existingBudget != null;

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
    _categoryController = locator.get<FinanceCategoryController>();

    if (widget.existingBudget != null) {
      final b = widget.existingBudget!;
      _selectedMonth = b.month;
      _titleController.text = b.title ?? '';
      _budgetType = b.budgetType;
      _periodType = b.periodType;
      _categories.addAll(b.categories);
      if (b.customTargetAmount != null) {
        _useCustomTarget = true;
        _customTargetController.text = b.customTargetAmount.toString();
      }
    } else if (widget.initialMonth != null) {
      _selectedMonth = widget.initialMonth!;
    } else {
      final now = DateTime.now();
      _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  void onReady() {
    _controller.refreshBudgetsWithSpentAmounts();
  }

  @override
  void onDispose() {
    _titleController.dispose();
    _customTargetController.dispose();
  }

  Future<void> _selectMonth() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You can only create a budget for the current month.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              formatMonthDisplay(_selectedMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (_categories.isEmpty) {
      AppToast.error(context, 'Please add at least one category');
      return;
    }

    setState(() => _isCreating = true);

    try {
      if (_isEditing) {
        await _saveEdits();
        if (mounted) {
          AppToast.success(context, 'Budget updated successfully!');
        }
      } else {
        await _createNew();
      }

      await _controller.refreshBudgetsWithSpentAmounts();
      if (mounted) context.goBack(true);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error ${_isEditing ? 'updating' : 'creating'} budget: $e');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _saveEdits() async {
    final budgetId = widget.existingBudget!.id!;
    final existingIds = widget.existingBudget!.categories
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toSet();
    final currentIds = _categories
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toSet();

    for (final id in existingIds) {
      if (!currentIds.contains(id)) {
        await _controller.deleteCategory(budgetId, id);
      }
    }

    for (final category in _categories) {
      if (category.id != null && existingIds.contains(category.id)) {
        await _controller.updateCategory(budgetId, category);
      } else {
        await _controller.addCategory(budgetId, category.copyWith(budgetId: budgetId));
      }
    }

    final customAmount =
        _useCustomTarget && _customTargetController.text.isNotEmpty
            ? double.tryParse(_customTargetController.text)
            : null;
    await _controller.updateBudget(
      widget.existingBudget!.copyWith(customTargetAmount: customAmount),
    );
  }

  Future<void> _createNew() async {
    final budget = Budget(
      month: _selectedMonth,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      budgetType: _budgetType,
      periodType: _periodType,
      categories: [],
      status: BudgetStatus.active,
      customTargetAmount:
          _useCustomTarget && _customTargetController.text.isNotEmpty
              ? double.tryParse(_customTargetController.text)
              : null,
    );

    final created = await _controller.createBudget(budget);
    if (created.id == null) throw Exception('Failed to get created budget ID');

    for (final category in _categories) {
      await _controller.addCategory(
        created.id!,
        category.copyWith(budgetId: created.id!),
      );
    }
  }

  void _copyBudgetCategories(String budgetId) {
    final source = (_controller.data ?? [])
        .cast<Budget?>()
        .firstWhere((b) => b?.id == budgetId, orElse: () => null);

    if (source == null) {
      AppToast.error(context, 'Could not find source budget');
      return;
    }

    setState(() {
      _budgetType = source.budgetType;
      _periodType = source.periodType;
      _categories
        ..clear()
        ..addAll(
          source.categories.map(
            (c) => BudgetCategory(
              budgetId: '',
              financeCategoryId: c.financeCategoryId,
              targetAmount: c.targetAmount,
              financeCategory: c.financeCategory,
            ),
          ),
        );
    });

    AppToast.success(context, 'Copied ${_categories.length} categories from ${source.title ?? formatMonthDisplay(source.month)}');
  }

  void _showCategoryDialog({BudgetCategory? editing}) {
    showDialog(
      context: context,
      builder: (context) => BudgetCategoryDialog(
        controller: _categoryController,
        budgetType: _budgetType,
        category: editing,
        existingCategories: _categories,
        onSave: (cat) {
          if (editing == null) {
            final isDuplicate = _categories.any(
              (e) => e.financeCategoryId == cat.financeCategoryId,
            );
            if (isDuplicate) {
              AppToast.show(context, 'This category is already added to the budget');
              return;
            }
          }
          setState(() {
            if (editing != null) {
              final index = _categories.indexOf(editing);
              if (index != -1) _categories[index] = cat;
            } else {
              _categories.add(cat);
            }
          });
        },
        onDelete: editing != null
            ? () {
                setState(() => _categories.remove(editing));
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget' : 'Create Budget'),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveBudget, child: const Text('SAVE')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              BudgetTitleField(
                controller: _titleController,
                periodType: _periodType,
              ),
              const SizedBox(height: 16),
              BudgetTypeCard(
                budgetType: _budgetType,
                isEditing: _isEditing,
                onChanged: (type) => setState(() {
                  _budgetType = type;
                  _categories.clear();
                }),
              ),
              const SizedBox(height: 8),
              BudgetPeriodTypeCard(
                periodType: _periodType,
                isEditing: _isEditing,
                onChanged: (type) => setState(() => _periodType = type),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Month'),
                  subtitle: Text(formatMonthDisplay(_selectedMonth)),
                  trailing: const Icon(Icons.info_outline),
                  onTap: _selectMonth,
                ),
              ),
              const SizedBox(height: 8),
              if (!_isEditing) ...[
                BudgetCopyFromCard(
                  controller: _controller,
                  selectedMonth: _selectedMonth,
                  copyFromBudget: _copyFromBudget,
                  sourceBudgetId: _sourceBudgetId,
                  onToggle: (v) => setState(() {
                    _copyFromBudget = v;
                    if (!v) {
                      _sourceBudgetId = null;
                      _categories.clear();
                    }
                  }),
                  onSourceSelected: (id) {
                    setState(() => _sourceBudgetId = id);
                    _copyBudgetCategories(id);
                  },
                ),
                const SizedBox(height: 8),
              ],
              BudgetCustomTargetCard(
                useCustomTarget: _useCustomTarget,
                customTargetController: _customTargetController,
                categoryTotal:
                    _categories.fold(0.0, (s, c) => s + c.targetAmount),
                onToggle: (v) => setState(() {
                  _useCustomTarget = v;
                  if (!v) _customTargetController.clear();
                }),
              ),
              const SizedBox(height: 16),
              BudgetCategoryFormList(
                categories: _categories,
                onAdd: () => _showCategoryDialog(),
                onEdit: (cat) => _showCategoryDialog(editing: cat),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isCreating ? null : _saveBudget,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isCreating
                    ? (_isEditing ? 'Updating...' : 'Creating...')
                    : (_isEditing ? 'Update Budget' : 'Create Budget'),
              ),
            )
          : null,
    );
  }
}
