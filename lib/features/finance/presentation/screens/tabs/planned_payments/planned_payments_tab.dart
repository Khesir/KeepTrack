import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/ui/responsive/desktop_aware_screen.dart';
import '../../../../modules/planned_payment/domain/entities/payment_enums.dart';
import '../../../../modules/planned_payment/domain/entities/planned_payment.dart';
import '../../../state/planned_payment_controller.dart';

/// Planned Payments Tab - Tracks recurring and scheduled payments
class PlannedPaymentsTabNew extends StatefulWidget {
  const PlannedPaymentsTabNew({super.key});

  @override
  State<PlannedPaymentsTabNew> createState() => _PlannedPaymentsTabNewState();
}

class _PlannedPaymentsTabNewState extends State<PlannedPaymentsTabNew> {
  late final PlannedPaymentController _controller;
  late final AccountController _accountController;
  late final FinanceCategoryController _categoryController;
  late final SupabaseService _supabaseService;
  String _selectedFilter = 'All'; // All, Active, Upcoming, Paused

  @override
  void initState() {
    super.initState();
    _controller = locator.get<PlannedPaymentController>();
    _accountController = locator.get<AccountController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _supabaseService = locator.get<SupabaseService>();

    // Load accounts and categories
    _accountController.loadAccounts();
    _categoryController.loadCategories();
  }

  Future<void> _showRecordPaymentDialog(PlannedPayment payment) async {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(2),
    );
    final feeController = TextEditingController(text: '0.00');
    final feeDescriptionController = TextEditingController();
    String? selectedAccountId;
    String? selectedCategoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Record Payment for ${payment.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount Field
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱',
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

              // Category Selector (expense categories only)
              AsyncStreamBuilder<List<FinanceCategory>>(
                state: _categoryController,
                builder: (context, categories) {
                  final expenseCategories = categories
                      .where((c) => c.type == CategoryType.expense)
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: expenseCategories
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
              const SizedBox(height: 16),

              // Fee Section
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: Theme.of(dialogContext).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Additional Fees (Optional)',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fee Amount Field
              TextField(
                controller: feeController,
                decoration: InputDecoration(
                  labelText: 'Fee Amount',
                  prefixText: '₱',
                  helperText: 'Tax, service charge, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),

              // Fee Description Field
              TextField(
                controller: feeDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Fee Description',
                  hintText: 'e.g., Tax, Service Charge',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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

              // Parse fee amount
              final fee = double.tryParse(feeController.text) ?? 0.0;
              final feeDescription =
                  feeDescriptionController.text.trim().isEmpty
                  ? null
                  : feeDescriptionController.text.trim();

              // Call RPC function
              try {
                await _supabaseService.client.rpc(
                  'create_planned_payment_transaction',
                  params: {
                    'p_user_id': _supabaseService.userId,
                    'p_account_id': selectedAccountId,
                    'p_finance_category_id': selectedCategoryId,
                    'p_amount': amount,
                    'p_type': 'expense',
                    'p_description': 'Paid: ${payment.name}',
                    'p_date': DateTime.now().toIso8601String(),
                    'p_notes': null,
                    'p_planned_payment_id': payment.id,
                    'p_fee': fee,
                    'p_fee_description': feeDescription,
                  },
                );

                // Reload planned payments
                _controller.loadPlannedPayments();

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
    feeDescriptionController.dispose();
  }

  Future<void> _skipPlannedPayment(PlannedPayment payment) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Payment'),
        content: Text(
          'Skip the next payment for "${payment.name}"?\n\n'
          'This will move the next payment date forward by one ${payment.frequency.displayName.toLowerCase()} without recording a transaction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _supabaseService.client.rpc(
        'skip_planned_payment',
        params: {
          'p_user_id': _supabaseService.userId,
          'p_planned_payment_id': payment.id,
        },
      );

      _controller.loadPlannedPayments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment skipped successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to skip payment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop ? AppColors.backgroundSecondary : null,
          body: AsyncStreamBuilder<List<PlannedPayment>>(
            state: _controller,
            builder: (context, payments) {
              // Calculate monthly total
              final monthlyTotal = payments
                  .where((p) => p.status == PaymentStatus.active)
                  .fold<double>(0, (sum, payment) => sum + payment.amount);

              // Get upcoming payments (next 7 days)
              final upcomingPayments = payments
                  .where(
                    (p) => p.isUpcoming && p.status == PaymentStatus.active,
                  )
                  .toList();

              // Filter payments
              final filteredPayments = _getFilteredPayments(
                payments,
                upcomingPayments,
              );

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
                              Text('Planned Payments', style: AppTextStyles.h1),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/planned-payments-management',
                                  );
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Manage Payments'),
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
                                'Monthly Total',
                                monthlyTotal,
                                Colors.purple,
                                Icons.calendar_month,
                                '${payments.where((p) => p.status == PaymentStatus.active).length} active payments',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Upcoming',
                                upcomingPayments.fold<double>(
                                  0,
                                  (sum, p) => sum + p.amount,
                                ),
                                Colors.orange,
                                Icons.notifications_active,
                                '${upcomingPayments.length} in next 7 days',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Upcoming Payments Alert
                        if (upcomingPayments.isNotEmpty) ...[
                          _buildUpcomingAlert(upcomingPayments),
                          const SizedBox(height: 24),
                        ],

                        // Filter Chips
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Active'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Upcoming'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Paused'),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredPayments.length} ${filteredPayments.length == 1 ? 'payment' : 'payments'}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payments List - Grid on Desktop
                        if (filteredPayments.isEmpty)
                          _buildEmptyState()
                        else if (isDesktop)
                          ResponsiveGrid(
                            spacing: AppSpacing.lg,
                            desktopChildAspectRatio: 1.1,
                            children: filteredPayments
                                .map((payment) => _buildPaymentCard(payment))
                                .toList(),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredPayments.length,
                            itemBuilder: (context, index) {
                              final payment = filteredPayments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildPaymentCard(payment),
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
                      'Error loading planned payments',
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
                      onPressed: () => _controller.loadPlannedPayments(),
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
                    Navigator.pushNamed(
                      context,
                      '/planned-payments-management',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Payments'),
                ),
        );
      },
    );
  }

  List<PlannedPayment> _getFilteredPayments(
    List<PlannedPayment> payments,
    List<PlannedPayment> upcomingPayments,
  ) {
    switch (_selectedFilter) {
      case 'Active':
        return payments.where((p) => p.status == PaymentStatus.active).toList();
      case 'Upcoming':
        return upcomingPayments;
      case 'Paused':
        return payments.where((p) => p.status == PaymentStatus.paused).toList();
      case 'All':
      default:
        return payments;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No planned payments found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track recurring bills and subscriptions here',
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAlert(List<PlannedPayment> upcomingPayments) {
    return Card(
      elevation: 0,
      color: Colors.orange[50],
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = 'Upcoming';
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notification_important,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Payments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You have ${upcomingPayments.length} ${upcomingPayments.length == 1 ? 'payment' : 'payments'} due in the next 7 days',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.orange[700],
              ),
            ],
          ),
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

  Widget _buildPaymentCard(PlannedPayment payment) {
    final daysUntilPayment = payment.daysUntilPayment;
    final isUpcoming = payment.isUpcoming;
    final isOverdue = payment.isOverdue;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to payment detail
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: payment.category.color, width: 4),
            ),
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
                        color: payment.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        payment.category.icon,
                        color: payment.category.color,
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
                            payment.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            payment.payee,
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
                        color: _getStatusColor(payment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(payment.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amount and Next Payment - Compact
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Amount',
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
                            ).format(payment.amount),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: payment.category.color,
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
                          'Next',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d').format(payment.nextPaymentDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? Colors.red
                                : isUpcoming
                                ? Colors.orange
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isUpcoming || isOverdue)
                          Text(
                            isOverdue
                                ? 'Overdue!'
                                : '${daysUntilPayment.abs()}d',
                            style: TextStyle(
                              fontSize: 10,
                              color: isOverdue ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Frequency Badge - Compact
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 12, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        payment.frequency.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons - Compact & Stacked
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: payment.status == PaymentStatus.active
                            ? () => _showRecordPaymentDialog(payment)
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Record',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: payment.status == PaymentStatus.active
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          foregroundColor:
                              payment.status == PaymentStatus.active
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                    if (payment.status == PaymentStatus.active &&
                        payment.frequency != PaymentFrequency.oneTime) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _skipPlannedPayment(payment),
                          icon: const Icon(Icons.skip_next, size: 16),
                          label: const Text(
                            'Skip',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: Colors.orange),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.active:
        return Colors.green;
      case PaymentStatus.paused:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.red;
      case PaymentStatus.closed:
        return Colors.grey;
    }
  }
}
