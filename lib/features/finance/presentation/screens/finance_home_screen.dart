import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'account_list_screen.dart';
import 'budget_list_screen.dart';

class FinanceHomeScreen extends ScopedScreen {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends ScopedScreenState<FinanceHomeScreen>
    with AppLayoutControlled {
  int _topIndex = 0;

  @override
  void registerServices() {
    // No services to register - using global controllers
  }

  @override
  void onReady() {
    configureLayout(title: 'Finance', showBottomNav: true);
  }

  final List<String> topTabs = ['Accounts', 'Budgets', 'Debts', 'Records'];

  void _onTabSelected(int index) {
    setState(() {
      _topIndex = index;
    });
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
              // Accounts Tab - using new AccountListScreen
              const AccountListScreen(),

              // Budgets Tab - using existing BudgetListScreen
              const BudgetListScreen(),

              // Goals Tab - TODO
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming soon - set and track financial goals',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Debts Tab - TODO
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Debts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming soon - track loans and debts',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
