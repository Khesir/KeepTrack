part of 'create_transaction_sheet.dart';

mixin _CreateTransactionSplitMixin on _CreateTransactionSheetBase {
  bool _splitMode = false;
  final List<SplitEntry> _splitEntries = [];

  double get _splitTotal => _splitEntries.fold(0.0, (s, e) => s + e.amount);

  bool get _splitBalanced =>
      _splitEntries.isNotEmpty &&
      (_splitTotal - _amount).abs() < 0.01 &&
      _splitEntries.every((e) => e.isValid);

  void _toggleSplit() {
    setState(() {
      _splitMode = !_splitMode;
      for (final e in _splitEntries) {
        TransactionImageService.deleteAll(e.id).ignore();
        e.dispose();
      }
      _splitEntries.clear();
      if (_splitMode) {
        _splitEntries.add(
          SplitEntry(type: _type)..amountCtrl.text = _amountCtrl.text,
        );
      }
    });
  }

  void _addSplitEntry() {
    setState(() => _splitEntries.add(SplitEntry(type: _type)));
  }

  void _removeSplitEntry(int index) {
    final entry = _splitEntries[index];
    TransactionImageService.deleteAll(entry.id).ignore();
    setState(() {
      entry.dispose();
      _splitEntries.removeAt(index);
    });
  }

  Future<void> _pickSplitCategory(int index) async {
    final entry = _splitEntries[index];
    final picked = await pickSplitEntryCategory(
      context,
      entry,
      _catController,
      _budgetController,
    );
    if (picked != null) setState(() => entry.category = picked);
  }
}
