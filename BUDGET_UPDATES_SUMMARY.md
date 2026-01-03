# Budget System Updates - Summary

## Overview
This update adds support for user-defined budget titles, separate income/expense budgets, and one-time vs monthly budgets. Multiple budgets can now be created for the same month.

## Changes Made

### 1. Database Schema (Migration 029)
**File:** `lib/core/migrations/migrations/029_add_budget_fields.dart`

**New Columns Added to `budgets` table:**
- `title` (TEXT, nullable) - User-defined budget name
- `budget_type` (TEXT, NOT NULL, default 'expense') - 'income' or 'expense'
- `period_type` (TEXT, NOT NULL, default 'monthly') - 'monthly' or 'oneTime'

**Constraints:**
- Check constraint on `budget_type` IN ('income', 'expense')
- Check constraint on `period_type` IN ('monthly', 'oneTime')
- Removed unique constraint on `(user_id, month)` to allow multiple budgets per month

**Indexes:**
- `idx_budgets_budget_type`
- `idx_budgets_period_type`
- `idx_budgets_user_month`

### 2. Domain Layer Updates

#### Budget Entity (`lib/features/finance/modules/budget/domain/entities/budget.dart`)
- Added `title` field
- Added `budgetType` enum field
- Added `periodType` enum field
- Added three new enums:
  - `BudgetType`: income, expense
  - `BudgetPeriodType`: monthly, oneTime
- Updated `copyWith()` method

#### Budget Model (`lib/features/finance/modules/budget/data/models/budget_model.dart`)
- Updated all methods to handle new fields: `fromJson()`, `toJson()`, `fromEntity()`, `withCategories()`

### 3. Data Layer Updates

#### Budget Datasource (`lib/features/finance/modules/budget/data/datasources/supabase/budget_datasource_supabase.dart`)
- Updated `createBudget()` to save new fields
- Updated `updateBudget()` to save new fields

### 4. Presentation Layer Updates

#### Create Budget Screen (`lib/features/finance/presentation/screens/configuration/budgets/create_budget_screen.dart`)

**New UI Components:**
- **Title Input Field**
  - Optional for monthly budgets
  - Required for one-time budgets
  - Validation included

- **Budget Type Selector**
  - Radio buttons for Income/Expense
  - Cannot be changed when editing
  - Clears categories when changed (to ensure proper category type filtering)

- **Period Type Selector**
  - Radio buttons for Monthly/One-Time
  - Shows description for each type
  - Cannot be changed when editing

**Category Filtering:**
- Income budgets: Only show income categories
- Expense budgets: Show expense, investment, savings, and transfer categories
- Implemented in `_CategoryDialog` widget

**Other Changes:**
- Removed month uniqueness validation
- Copy budget now also copies budget type and period type
- Updated state management for new fields

#### Budget Management Screen (`lib/features/finance/presentation/screens/configuration/budgets/budget_management_screen.dart`)

**Budget Card Updates:**
- Shows budget title (or month if no title)
- Icon color based on budget type (green for income, red for expense)
- Displays period type badge (blue for monthly, purple for one-time)
- Shows status badge (green for active, grey for closed)
- Displays month information

#### Budget Controller (`lib/features/finance/presentation/state/budget_controller.dart`)
- Removed `budgetExistsForMonth()` method (no longer needed)

## How to Apply the Migration

### Option 1: Automatic (When App Starts)
The migration will run automatically the next time you start the app. The migration system will detect the new migration and apply it.

### Option 2: Manual (Supabase Dashboard)
1. Open Supabase SQL Editor
2. Copy the SQL from `029_add_budget_fields.dart` (lines 19-113 in the `up()` method)
3. Execute the SQL

## Features Added

### ✅ User-Defined Budget Titles
- Name your budgets with custom titles
- Examples: "Vacation Fund", "Wedding Budget", "Emergency Savings"
- Optional for monthly budgets, recommended for one-time budgets

### ✅ Separate Income & Expense Budgets
- Create dedicated income budgets to track expected income
- Create expense budgets to track spending
- Categories are automatically filtered based on budget type

### ✅ One-Time vs Monthly Budgets
- **Monthly Budgets**: Recurring monthly financial planning
- **One-Time Budgets**: For specific events or projects (vacations, weddings, etc.)
- Visual indicators show the period type

### ✅ Multiple Budgets Per Month
- No longer limited to one budget per month
- Create as many budgets as needed for different purposes
- Example: "January Expenses", "Vacation Jan-Feb", "Monthly Income January"

### ✅ Category Filtering
- Income budgets only show income categories
- Expense budgets show expense-related categories
- Prevents incorrect category selection

## UI/UX Improvements

### Budget Creation Flow
1. Enter optional budget title
2. Select budget type (Income/Expense)
3. Select period type (Monthly/One-Time)
4. Select month
5. Add categories (automatically filtered by budget type)

### Budget Display
- Clear visual hierarchy with title prominently displayed
- Color-coded icons for budget type
- Badges for period type and status
- Month information for context

## Testing Checklist

- [ ] Migration runs successfully
- [ ] Create a monthly expense budget
- [ ] Create a monthly income budget
- [ ] Create a one-time budget (with title required)
- [ ] Create multiple budgets for the same month
- [ ] Verify category filtering (income vs expense)
- [ ] Edit existing budgets
- [ ] Copy budget preserves budget type and period type
- [ ] Budget cards display correctly in management screen
- [ ] Existing budgets still work (default to expense/monthly)

## Database Migration Details

**Migration Number:** 029
**Migration File:** `lib/core/migrations/migrations/029_add_budget_fields.dart`
**Registered In:** `lib/core/migrations/migration_manager.dart`

**Backwards Compatible:** ✅ Yes
- Existing budgets default to `budget_type='expense'` and `period_type='monthly'`
- All new columns are nullable or have defaults
- No data loss on migration

**Rollback Available:** ✅ Yes
- `down()` method provided in migration file
- WARNING: Rollback will delete title, budget_type, and period_type data

## Files Modified

### Domain Layer
- `lib/features/finance/modules/budget/domain/entities/budget.dart`
- `lib/features/finance/modules/budget/data/models/budget_model.dart`

### Data Layer
- `lib/features/finance/modules/budget/data/datasources/supabase/budget_datasource_supabase.dart`

### Presentation Layer
- `lib/features/finance/presentation/screens/configuration/budgets/create_budget_screen.dart`
- `lib/features/finance/presentation/screens/configuration/budgets/budget_management_screen.dart`
- `lib/features/finance/presentation/state/budget_controller.dart`

### Migration
- `lib/core/migrations/migrations/029_add_budget_fields.dart` (NEW)
- `lib/core/migrations/migration_manager.dart`

## Notes

1. **Validation**: One-time budgets require a title, monthly budgets don't
2. **Default Values**: New budgets default to expense/monthly if not specified
3. **Category Filtering**: Based on budget type, not manually configurable
4. **Month Format**: Still uses YYYY-MM format (e.g., "2026-01")
5. **Multiple Budgets**: No limit on budgets per month

## Support

If you encounter any issues:
1. Check migration ran successfully: Look for "✅ Budget fields added successfully" in logs
2. Verify database schema: Check if columns exist in budgets table
3. Check for errors: Run `flutter analyze` to check for code issues
4. Rollback if needed: Use migration's `down()` method

---

**Implementation Date:** 2026-01-02
**Migration Version:** 029
**Status:** ✅ Ready for Testing
