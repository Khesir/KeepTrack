# TransactionCategoryPicker has a single canonical implementation

`create_transaction_sheet.dart` contained a private duplicate of
`TransactionCategoryPicker`, separate from the existing
`presentation/widgets/transaction_category_picker.dart`. Two other files,
`transaction_detail_sheet.dart` and `scan_expenses_sheet.dart`, were importing
the private duplicate via `show TransactionCategoryPicker` from
`create_transaction_sheet.dart` instead of using the shared widget.

As part of splitting `create_transaction_sheet.dart` (Candidate 2 of the
architecture review), the private duplicate was removed and all three files
now use `presentation/widgets/transaction_category_picker.dart`.

`presentation/widgets/transaction_category_picker.dart` is the only
`TransactionCategoryPicker` going forward. New category-picking UI in the
finance feature should use this widget rather than building a local variant.
