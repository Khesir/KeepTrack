import 'package:flutter/material.dart';
import 'package:persona_codex/core/state/state.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'package:persona_codex/features/finance/domain/repositories/account_repository.dart';
import 'package:persona_codex/features/finance/domain/usecases/account/get_accounts_usecase.dart';
import 'package:persona_codex/features/finance/domain/usecases/usecases.dart';
import 'package:persona_codex/features/finance/presentation/state/finance_home_controller.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/budget_record.dart';

class FinanceHomeScreen extends ScopedScreen {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends ScopedScreenState<FinanceHomeScreen>
    with AppLayoutControlled {
  int _topIndex = 0;
  late AccountController _controller;
  @override
  void registerServices() {
    // Uses global repository
    final accountRepo = getService<AccountRepository>();
    scope.registerFactory<AccountController>(
      () => AccountController(
        getAccountsUsecase: GetAccountsUsecase(accountRepo),
        createAccountUsecase: CreateAccountUsecase(accountRepo),
        updateAccountUsecase: UpdateAccountUsecase(accountRepo),
        deleteAccountUsecase: DeleteAccountUsecase(accountRepo),
        archiveAccountUsecase: ArchiveAccountUsecase(accountRepo),
        adjustAccountBalanceUsecase: AdjustAccountBalanceUsecase(accountRepo),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = scope.get<AccountController>();
  }

  @override
  void onReady() {
    // Only UI configuration here (if needed)
    configureLayout(
      title: 'Finance',
      fab: Container(
        height: 70,
        width: 70,
        margin: const EdgeInsets.only(top: 8),
        child: FloatingActionButton(
          backgroundColor: Colors.blueAccent,
          shape: const CircleBorder(),
          elevation: 6,
          onPressed: () {
            Navigator.pushNamed(context, '/create');
          },
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
      fabPosition: FabPosition.centerDocked,
      showBottomNav: true,
    );
    _controller.loadAccounts();
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up streams
    super.dispose();
  }

  final List<String> topTabs = ['Accounts', 'Goals', 'Debts', 'Transactions'];
  List<BudgetRecord> _getSampleRecords(Account account) {
    return [
      BudgetRecord(
        id: 'r1',
        budgetId: 'b1',
        categoryId: 'c1',
        amount: 500,
        description: 'Salary',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: RecordType.income,
      ),
      BudgetRecord(
        id: 'r2',
        budgetId: 'b1',
        categoryId: 'c2',
        amount: 120,
        description: 'Groceries',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: RecordType.expense,
      ),
      BudgetRecord(
        id: 'r3',
        budgetId: 'b1',
        categoryId: 'c3',
        amount: 60,
        description: 'Coffee',
        date: DateTime.now(),
        type: RecordType.expense,
      ),
    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _topIndex = index;
    });

    // Optional: you can also trigger controller reloads per tab
    switch (_topIndex) {
      case 0: // Accounts
        _controller.loadAccounts();
        break;
      case 1: // Goals
        // _controller.loadGoals(); // if implemented later
        break;
      case 2: // Debts
        // _controller.loadDebts(); // if implemented later
        break;
      case 3: // Transactions
        // _controller.loadTransactions(); // if implemented later
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inner top tabs
        Container(
          color: Colors.blue[50],
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(topTabs.length, (index) {
              final isActive = _topIndex == index;
              return GestureDetector(
                onTap: () => _onTabSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topTabs[index],
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? Colors.blueAccent : Colors.grey[700],
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 40,
                        color: Colors.blueAccent,
                      ),
                  ],
                ),
              );
            }),
          ),
        ),

        // Inner tab content
        Expanded(
          child: IndexedStack(
            index: _topIndex,
            children: [
              // Accounts Tab with transactions
              AsyncStreamBuilder<List<Account>>(
                state: _controller,
                builder: (context, accounts) {
                  if (accounts.isEmpty) {
                    return const Center(child: Text('No accounts'));
                  }

                  return ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];

                      return ExpansionTile(
                        title: Text(account.name),
                        subtitle: Text(
                          'Balance: ${account.balance.toStringAsFixed(2)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/createTransaction',
                              arguments: account,
                            ).then((_) => _controller.loadAccounts());
                          },
                        ),
                        children: [
                          // Hardcoded transactions for now
                          ..._getSampleRecords(account).map(
                            (BudgetRecord record) => ListTile(
                              leading: Icon(
                                record.type == RecordType.income
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: record.type == RecordType.income
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(record.description ?? '-'),
                              subtitle: Text(
                                record.date.toLocal().toString().split(' ')[0],
                              ),
                              trailing: Text(
                                '${record.type == RecordType.income ? '+' : '-'}${record.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: record.type == RecordType.income
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/transactionDetail',
                                  arguments: record,
                                ).then((_) => _controller.loadAccounts());
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // Goals Tab
              const Center(child: Text('Goals Tab')),

              // Debts Tab
              const Center(child: Text('Debts Tab')),

              // Transactions Tab
              const Center(child: Text('Transactions Tab')),
            ],
          ),
        ),
      ],
    );
  }
}
