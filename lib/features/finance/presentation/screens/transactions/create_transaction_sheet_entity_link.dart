part of 'create_transaction_sheet.dart';

mixin _CreateTransactionEntityLinkMixin on _CreateTransactionSheetBase {
  late final DebtController _debtController;
  late final GoalController _goalController;
  late final SubscriptionController _subController;

  String? _entityType;
  String? _entityLabel;
  String? _debtId;
  String? _goalId;
  String? _subscriptionId;

  @override
  void initState() {
    super.initState();
    _debtController = locator.get<DebtController>();
    _goalController = locator.get<GoalController>();
    _subController = locator.get<SubscriptionController>();
  }

  void _pickMainEntity() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCreateEntityTypeSheet(
        isIncome: _type == TransactionType.income,
        currentEntityType: _entityType,
        onSelectNone: () => setState(() {
          _entityType = null;
          _entityLabel = null;
          _debtId = null;
          _goalId = null;
          _subscriptionId = null;
        }),
        onSelectType: (type) {
          setState(() {
            _entityType = type;
            _entityLabel = null;
            _debtId = null;
            _goalId = null;
            _subscriptionId = null;
            _category = null;
          });
          _pickMainEntityItem(type);
        },
      ),
    );
  }

  void _pickMainEntityItem(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCreateEntityItemSheet(
        entityType: type,
        debtController: _debtController,
        goalController: _goalController,
        subController: _subController,
        currentDebtId: _debtId,
        currentGoalId: _goalId,
        currentSubscriptionId: _subscriptionId,
        onSelect: (id, label) {
          setState(() {
            _entityLabel = label;
            if (type == 'debt_payment' ||
                type == 'debt_received' ||
                type == 'lending')
              _debtId = id;
            if (type == 'goal') _goalId = id;
            if (type == 'subscription') {
              _subscriptionId = id;
              final sub = _subController.data
                  ?.where((s) => s.id == id)
                  .firstOrNull;
              if (sub != null) {
                _amountCtrl.text = sub.amount.toStringAsFixed(2);
              }
            }
          });
        },
      ),
    );
  }

  String? _buildEntityMeta() => buildEntityMeta(
    entityType: _entityType,
    debtId: _debtId,
    goalId: _goalId,
    subscriptionId: _subscriptionId,
    debtController: _debtController,
    goalController: _goalController,
    subController: _subController,
  );
}
