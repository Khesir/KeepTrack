part of 'create_transaction_sheet.dart';

mixin _CreateTransactionPickersMixin on _CreateTransactionSheetBase {
  void _pickBudgetProfile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCreateProfilePickerSheet(
        isDark: isDark,
        profiles: _profileController.data ?? <BudgetProfile>[],
        plans: _monthPlanController.data ?? [],
        selectedProfileId: _selectedProfileId,
        selectedPlanMonth: _selectedPlanMonth,
        onSelect: (profileId, profileName, planMonth) {
          setState(() {
            _selectedProfileId = profileId;
            _selectedProfileName = profileName;
            _selectedPlanMonth = planMonth;
            _category = null;
          });
        },
      ),
    );
  }

  void _pickCategory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCategoryPicker(
        type: _type,
        selectedId: _category?.id,
        controller: _catController,
        allowedIds: allowedCategoryIdsForProfile(
          _budgetController,
          _selectedProfileId,
          _selectedPlanMonth,
        ),
        isDark: isDark,
        onSelect: (cat) {
          setState(() {
            _category = cat;
            _categoryError = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickWallet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCreateWalletPickerSheet(
        isDark: isDark,
        wallets: _walletController.data ?? [],
        type: _type,
        selectedWalletId: _selectedWallet?.id,
        onSelect: (w) => setState(() {
          _selectedWallet = w;
          _walletError = false;
        }),
      ),
    );
  }

  void _pickDate() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCreateDatePickerSheet(
        selected: _date,
        isDark: isDark,
        allowFuture: _isPlan,
        onSelect: (d) {
          setState(() => _date = d);
          Navigator.pop(context);
        },
      ),
    );
  }
}
