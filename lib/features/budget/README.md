# Budget Management Feature

Monthly budget tracking with categories, records, and surplus/deficit analysis.

## Overview

The budget feature allows users to:
- Create monthly budgets with income and expense categories
- Set target amounts for each category
- Track actual transactions (records)
- View surplus or deficit in real-time
- Close budgets with notes for historical tracking
- View budget history with visual graphs

## Architecture

```
features/budget/
├── domain/                      # Business logic layer
│   ├── entities/
│   │   ├── budget.dart          # Main budget entity
│   │   ├── budget_category.dart # Category entity
│   │   └── budget_record.dart   # Transaction entity
│   └── repositories/
│       └── budget_repository.dart
│
├── data/                        # Data layer
│   ├── models/
│   │   ├── budget_model.dart
│   │   ├── budget_category_model.dart
│   │   └── budget_record_model.dart
│   ├── datasources/
│   │   ├── budget_datasource.dart
│   │   └── mongodb/
│   │       └── budget_datasource_mongodb.dart
│   └── repositories/
│       └── budget_repository_impl.dart
│
├── presentation/                # UI layer
│   └── screens/
│       ├── budget_list_screen.dart
│       ├── budget_detail_screen.dart
│       └── create_budget_screen.dart
│
├── budget_di.dart               # DI setup
└── budget.dart                  # Barrel export
```

## Domain Entities

### Budget

Main entity representing a monthly budget period.

```dart
Budget(
  id: 'budget-1',
  month: '2024-12',  // YYYY-MM format
  categories: [
    BudgetCategory(...),
    BudgetCategory(...),
  ],
  records: [
    BudgetRecord(...),
  ],
  status: BudgetStatus.active,
  notes: 'Year-end budget',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

**Properties:**
- `id` - Unique identifier
- `month` - Budget period (YYYY-MM)
- `categories` - List of budget categories
- `records` - List of transactions
- `status` - active or closed
- `notes` - Optional notes when closing
- `createdAt`, `updatedAt`, `closedAt` - Timestamps

**Calculated Properties:**
- `totalBudgetedIncome` - Sum of all income category targets
- `totalBudgetedExpenses` - Sum of all expense/investment/savings targets
- `totalActualIncome` - Sum of all income records
- `totalActualExpenses` - Sum of all expense records
- `balance` - Actual income - Actual expenses
- `budgetedBalance` - Budgeted income - Budgeted expenses
- `isOverBudget` - True if expenses exceed budget
- `hasSurplus` - True if under budget
- `variance` - Difference from budgeted balance

### BudgetCategory

Represents a budget category with a target amount.

```dart
BudgetCategory(
  id: 'cat-1',
  name: 'Salary',
  type: CategoryType.income,
  targetAmount: 5000.0,
);
```

**Category Types:**
- `income` - Money coming in
- `expense` - Regular expenses
- `investment` - Investment allocations
- `savings` - Savings targets

### BudgetRecord

Individual transaction/record within a budget.

```dart
BudgetRecord(
  id: 'rec-1',
  budgetId: 'budget-1',
  categoryId: 'cat-1',
  amount: 500.0,
  description: 'Grocery shopping',
  date: DateTime.now(),
  type: RecordType.expense,
);
```

**Record Types:**
- `income` - Money received
- `expense` - Money spent

## Features

### 1. Create Monthly Budget

Create a new budget for a specific month with categories:

```dart
final budget = Budget(
  id: generateId(),
  month: '2024-12',
  categories: [
    BudgetCategory(
      id: 'cat-1',
      name: 'Salary',
      type: CategoryType.income,
      targetAmount: 5000.0,
    ),
    BudgetCategory(
      id: 'cat-2',
      name: 'Housing',
      type: CategoryType.expense,
      targetAmount: 1500.0,
    ),
  ],
  status: BudgetStatus.active,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await budgetRepository.createBudget(budget);
```

### 2. Add Transactions

Record income or expenses:

```dart
final record = BudgetRecord(
  id: generateId(),
  budgetId: budget.id,
  categoryId: 'cat-2', // Housing
  amount: 1500.0,
  description: 'Monthly rent',
  date: DateTime.now(),
  type: RecordType.expense,
);

await budgetRepository.addRecord(budget.id, record);
```

### 3. Track Surplus/Deficit

Budget automatically calculates:

```dart
// Get budget
final budget = await budgetRepository.getBudgetById('budget-1');

// Check status
if (budget.hasSurplus) {
  print('Under budget by \$${budget.balance}');
} else if (budget.isOverBudget) {
  print('Over budget by \$${-budget.balance}');
}
```

### 4. Close Budget

Close a budget period with notes:

```dart
await budgetRepository.closeBudget(
  budget.id,
  'Successfully stayed under budget this month!',
);
```

### 5. View Budget History

List all budgets (sorted by month):

```dart
final budgets = await budgetRepository.getBudgets();
// Returns budgets sorted by month (newest first)
```

## UI Screens

### BudgetListScreen

Shows all monthly budgets with:
- Current month summary card
- List of all budgets
- Visual progress bars for income/expenses
- Surplus/deficit indicators
- Over budget warnings

### CreateBudgetScreen

Create a new budget:
- Select month (YYYY-MM)
- Add categories with target amounts
- Default templates provided
- Category type selection

### BudgetDetailScreen

View/manage a specific budget:
- Summary card with balance
- Category breakdown with progress
- Transaction list
- Add new transactions
- Close budget with notes

## Business Rules

### Creating Budgets
- ✅ One budget per month recommended
- ✅ Can have multiple active budgets
- ✅ Must have at least one category

### Categories
- ✅ 4 category types: income, expense, investment, savings
- ✅ Target amount must be positive
- ⚠️ Cannot delete category with existing records

### Records
- ✅ Must belong to a category
- ✅ Amount must be positive
- ✅ Type (income/expense) independent of category type
- ✅ Can add records to active budgets only (unless modified)

### Closing Budgets
- ✅ Can close active budgets
- ✅ Optional notes when closing
- ✅ Cannot modify closed budgets (unless reopened)
- ✅ Closed budgets kept for history

## Calculations

### Income/Expense Totals

```dart
// Total budgeted income
final budgetedIncome = budget.categories
    .where((c) => c.type == CategoryType.income)
    .fold(0.0, (sum, c) => sum + c.targetAmount);

// Total actual income
final actualIncome = budget.records
    .where((r) => r.type == RecordType.income)
    .fold(0.0, (sum, r) => sum + r.amount);
```

### Balance

```dart
// Current balance
final balance = actualIncome - actualExpenses;

// Budgeted balance
final budgetedBalance = budgetedIncome - budgetedExpenses;

// Variance
final variance = balance - budgetedBalance;
```

### Category Progress

```dart
// For each category
final actualAmount = budget.records
    .where((r) => r.categoryId == category.id)
    .fold(0.0, (sum, r) => sum + r.amount);

final percentage = actualAmount / category.targetAmount;
```

## Database Schema

### Budget Collection

```json
{
  "_id": "budget-1",
  "month": "2024-12",
  "categories": [
    {
      "id": "cat-1",
      "name": "Salary",
      "type": "income",
      "targetAmount": 5000.0
    },
    {
      "id": "cat-2",
      "name": "Housing",
      "type": "expense",
      "targetAmount": 1500.0
    }
  ],
  "records": [
    {
      "id": "rec-1",
      "budgetId": "budget-1",
      "categoryId": "cat-2",
      "amount": 1500.0,
      "description": "Monthly rent",
      "date": "2024-12-01T00:00:00.000Z",
      "type": "expense"
    }
  ],
  "status": "active",
  "notes": null,
  "createdAt": "2024-12-01T00:00:00.000Z",
  "updatedAt": "2024-12-01T00:00:00.000Z",
  "closedAt": null
}
```

## Usage Examples

### Example 1: Complete Monthly Budget Flow

```dart
// 1. Create budget
final budget = await budgetRepository.createBudget(Budget(
  id: generateId(),
  month: '2024-12',
  categories: [
    BudgetCategory(id: '1', name: 'Salary', type: CategoryType.income, targetAmount: 5000),
    BudgetCategory(id: '2', name: 'Rent', type: CategoryType.expense, targetAmount: 1500),
    BudgetCategory(id: '3', name: 'Food', type: CategoryType.expense, targetAmount: 500),
  ],
  status: BudgetStatus.active,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
));

// 2. Add income
await budgetRepository.addRecord(budget.id, BudgetRecord(
  id: generateId(),
  budgetId: budget.id,
  categoryId: '1',
  amount: 5000,
  description: 'Monthly salary',
  date: DateTime.now(),
  type: RecordType.income,
));

// 3. Add expenses
await budgetRepository.addRecord(budget.id, BudgetRecord(
  id: generateId(),
  budgetId: budget.id,
  categoryId: '2',
  amount: 1500,
  description: 'Rent payment',
  date: DateTime.now(),
  type: RecordType.expense,
));

// 4. Check status
final updated = await budgetRepository.getBudgetById(budget.id);
print('Balance: \$${updated.balance}'); // Balance: $3500
print('Has surplus: ${updated.hasSurplus}'); // true

// 5. Close budget
await budgetRepository.closeBudget(budget.id, 'Good month!');
```

### Example 2: Category-wise Tracking

```dart
final budget = await budgetRepository.getBudgetById('budget-1');

for (final category in budget.categories) {
  final actual = budget.getActualAmountForCategory(category.id);
  final percentage = (actual / category.targetAmount * 100).toStringAsFixed(1);

  print('${category.name}: \$$actual / \$${category.targetAmount} ($percentage%)');
}
```

## Future Enhancements

- [ ] Budget templates
- [ ] Recurring transactions
- [ ] Multi-month projections
- [ ] Category budgets across months
- [ ] Export to CSV/PDF
- [ ] Budget alerts (approaching limit)
- [ ] Category-wise graphs
- [ ] Budget comparisons (month-to-month)
- [ ] Savings goals tracking
- [ ] Bill reminders

## Testing

```dart
void main() {
  setUp(() {
    locator.reset();
    setupBudgetDependencies();
  });

  test('should calculate balance correctly', () async {
    final repo = MockBudgetRepository();
    locator.registerSingleton<BudgetRepository>(repo);

    final budget = Budget(...);
    expect(budget.balance, equals(expectedBalance));
  });
}
```
