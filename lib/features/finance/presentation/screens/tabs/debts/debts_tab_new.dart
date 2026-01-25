import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../../modules/debt/domain/entities/debt.dart';
import '../../../state/debt_controller.dart';

import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';

/// Debts Tab - Tracks Lending (money lent out) and Borrowing (money owed)
class DebtsTabNew extends StatefulWidget {
  const DebtsTabNew({super.key});

  @override
  State<DebtsTabNew> createState() => _DebtsTabNewState();
}

class _DebtsTabNewState extends State<DebtsTabNew> {
  late final DebtController _controller;
  late final AccountController _accountController;
  late final FinanceCategoryController _categoryController;
  late final SupabaseService _supabaseService;
  String _selectedFilter = 'All'; // All, Lending, Borrowing

  @override
  void initState() {
    super.initState();
    _controller = locator.get<DebtController>();
    _accountController = locator.get<AccountController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _supabaseService = locator.get<SupabaseService>();

    // Load accounts and categories
    _accountController.loadAccounts();
    _categoryController.loadCategories();
  }

  Future<void> _showRecordPaymentDialog(Debt debt) async {
    final amountController = TextEditingController();
    final feeController = TextEditingController();
    String? selectedAccountId;
    String? selectedCategoryId;

    // Determine transaction type based on debt type
    final isLending = debt.type == DebtType.lending;
    final transactionType = isLending ? 'income' : 'expense';
    final categoryType = isLending ? CategoryType.income : CategoryType.expense;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isLending
              ? 'Record Payment from ${debt.personName}'
              : 'Record Payment to ${debt.personName}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount Field
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: currencyFormatter.currencySymbol,
                  hintText: debt.monthlyPaymentAmount > 0
                      ? 'Suggested: ${debt.monthlyPaymentAmount.toStringAsFixed(2)}'
                      : 'Enter payment amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Fee Field
              TextField(
                controller: feeController,
                decoration: InputDecoration(
                  labelText: 'Fee Amount (Optional)',
                  prefixText: currencyFormatter.currencySymbol,
                  hintText: 'Processing/service fee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Account Selector
              AsyncStreamBuilder<List<Account>>(
                state: _accountController,
                builder: (context, accounts) {
                  return DropdownButtonFormField<String>(
                    value: selectedAccountId,
                    decoration: InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: accounts
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedAccountId = value,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              AsyncStreamBuilder<List<FinanceCategory>>(
                state: _categoryController,
                builder: (context, categories) {
                  final filteredCategories = categories
                      .where((c) => c.type == categoryType)
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: filteredCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedCategoryId = value,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              if (amount > debt.remainingAmount) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Amount cannot exceed remaining debt of ${currencyFormatter.currencySymbol}${debt.remainingAmount.toStringAsFixed(2)}',
                    ),
                  ),
                );
                return;
              }

              if (selectedAccountId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please select an account')),
                );
                return;
              }

              if (selectedCategoryId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please select a category')),
                );
                return;
              }

              // Call RPC function
              try {
                final fee = double.tryParse(feeController.text) ?? 0;
                await _supabaseService.client.rpc(
                  'create_debt_payment_transaction',
                  params: {
                    'p_user_id': _supabaseService.userId,
                    'p_account_id': selectedAccountId,
                    'p_finance_category_id': selectedCategoryId,
                    'p_amount': amount,
                    'p_type': transactionType,
                    'p_description': isLending
                        ? 'Received payment from ${debt.personName}'
                        : 'Paid debt to ${debt.personName}',
                    'p_date': DateTime.now().toIso8601String(),
                    'p_notes': null,
                    'p_debt_id': debt.id,
                    'p_fee': fee,
                  },
                );

                // Reload debts
                _controller.loadDebts();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to record payment: $e')),
                  );
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    }

    amountController.dispose();
    feeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF09090B) : AppColors.backgroundSecondary) : null,
          body: AsyncStreamBuilder<List<Debt>>(
            state: _controller,
            builder: (context, debts) {
              // Calculate totals
              final totalLending = debts
                  .where((d) => d.type == DebtType.lending)
                  .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

              final totalBorrowing = debts
                  .where((d) => d.type == DebtType.borrowing)
                  .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

              // Filter debts
              final filteredDebts = _selectedFilter == 'All'
                  ? debts
                  : debts.where((d) {
                      switch (_selectedFilter) {
                        case 'Lending':
                          return d.type == DebtType.lending;
                        case 'Borrowing':
                          return d.type == DebtType.borrowing;
                        default:
                          return true;
                      }
                    }).toList();

              // Sort debts by status
              filteredDebts.sort((a, b) {
                int getStatusPriority(DebtStatus status) {
                  switch (status) {
                    case DebtStatus.overdue:
                      return 0;
                    case DebtStatus.active:
                      return 1;
                    case DebtStatus.settled:
                      return 2;
                    default:
                      return 3;
                  }
                }

                return getStatusPriority(
                  a.status,
                ).compareTo(getStatusPriority(b.status));
              });

              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        if (isDesktop)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Debts & Lending', style: AppTextStyles.h1),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/debts-management',
                                  );
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Manage Debts'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (isDesktop) SizedBox(height: AppSpacing.xl),

                        // Summary Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Lending',
                                totalLending,
                                Colors.green,
                                Icons.arrow_upward,
                                'Money you lent',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Borrowing',
                                totalBorrowing,
                                Colors.red,
                                Icons.arrow_downward,
                                'Money you owe',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Net Balance Card
                        _buildNetBalanceCard(totalLending - totalBorrowing),
                        const SizedBox(height: 24),

                        // Filter Chips
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Lending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Borrowing'),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredDebts.length} ${filteredDebts.length == 1 ? 'debt' : 'debts'}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Debts List - Grid on Desktop
                        if (filteredDebts.isEmpty)
                          _buildEmptyState()
                        else if (isDesktop)
                          ResponsiveGrid(
                            spacing: AppSpacing.lg,
                            desktopChildAspectRatio: 1.2,
                            children: filteredDebts
                                .map((debt) => _buildDebtCard(debt))
                                .toList(),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDebts.length,
                            itemBuilder: (context, index) {
                              final debt = filteredDebts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildDebtCard(debt),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loadingBuilder: (_) => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            errorBuilder: (context, message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading debts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _controller.loadDebts(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/debts-management');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Debts'),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No debts found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track lending and borrowing activities here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              NumberFormat.currency(
                symbol: currencyFormatter.currencySymbol,
                decimalDigits: 2,
              ).format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(double netBalance) {
    final isPositive = netBalance >= 0;
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [Colors.blue[700]!, Colors.blue[500]!]
                : [Colors.orange[700]!, Colors.orange[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      symbol: currencyFormatter.currencySymbol,
                      decimalDigits: 2,
                    ).format(netBalance.abs()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isPositive ? 'You are owed more' : 'You owe more',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isLending = debt.type == DebtType.lending;
    final color = isLending ? Colors.green : Colors.red;
    final progress = debt.progress;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to debt detail
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Compact
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isLending ? Icons.call_made : Icons.call_received,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            debt.personName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            debt.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(debt.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        debt.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(debt.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amount Info - Compact
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(
                              symbol: currencyFormatter.currencySymbol,
                              decimalDigits: 0,
                            ).format(debt.remainingAmount),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Original',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          NumberFormat.currency(
                            symbol: currencyFormatter.currencySymbol,
                            decimalDigits: 0,
                          ).format(debt.originalAmount),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar - Compact
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Compact Date Info
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        debt.dueDate != null
                            ? 'Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}'
                            : 'Started: ${DateFormat('MMM d, yyyy').format(debt.startDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: debt.isOverdue
                              ? Colors.red
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: debt.isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Button - Compact
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRecordPaymentDialog(debt),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Record', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: color),
                      foregroundColor: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.active:
        return Colors.blue;
      case DebtStatus.overdue:
        return Colors.red;
      case DebtStatus.settled:
        return Colors.green;
    }
  }

  Color _getDueDateColor(DateTime dueDate, bool isOverdue) {
    if (isOverdue) {
      return Colors.red;
    }
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    if (daysUntilDue <= 7) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  }
}
