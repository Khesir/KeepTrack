# Scan-flow pickers stay separate from transaction-detail pickers

While splitting `scan_expenses_sheet.dart` and `transaction_detail_sheet.dart`
(Candidate 2 of the architecture review), several picker sheets in the scan
flow looked like duplicates of pickers already extracted from the transaction
detail flow: `ScanProfilePickerSheet` vs. `TransactionProfilePickerSheet`, and
`ScanEntityLinkPickerSheet` vs. `EntityLinkPickerSheet`.

These were kept as separate classes rather than merged. `ScanProfilePickerSheet`
intentionally has no "None" option, unlike `TransactionProfilePickerSheet`.
`ScanEntityLinkPickerSheet` does hint-based filtering and shows a
"Suggested: ..." entry based on the scanned receipt, which `EntityLinkPickerSheet`
does not. `ScanWalletPickerSheet` was extracted alongside them for the same
reason — the scan flow's picker UX is driven by scan-specific context that the
transaction-detail pickers don't have.

If the scan flow's picker UX is ever redesigned to match the transaction
detail flow exactly, these pairs should be merged at that point. Until then,
treat `presentation/sheets/scan_*` pickers as the scan flow's own pickers, not
duplicates to be cleaned up.
