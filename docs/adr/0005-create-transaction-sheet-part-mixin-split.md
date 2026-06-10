# create_transaction_sheet.dart splits its State via part/part-of mixins

After extracting reusable sections, sheets, widgets, and helpers out of
`create_transaction_sheet.dart` (Candidate 2 of the architecture review), the
remaining `_CreateTransactionSheetState` was still 685 lines — over the
CLAUDE.md 500-line limit, but not further decomposable into separate widgets
because its methods share a large set of private mutable fields
(controllers, selected category/wallet/date, split state, entity-link state).

The state class was split by responsibility into three `part`/`part of`
files in the same library — `create_transaction_sheet_entity_link.dart`
(`_CreateTransactionEntityLinkMixin`), `create_transaction_sheet_split.dart`
(`_CreateTransactionSplitMixin`), and `create_transaction_sheet_pickers.dart`
(`_CreateTransactionPickersMixin`) — plus a new abstract
`_CreateTransactionSheetBase extends State<CreateTransactionSheet>` holding
the shared private fields. Each mixin is declared `on _CreateTransactionSheetBase`,
and `_CreateTransactionSheetState extends _CreateTransactionSheetBase with
_CreateTransactionEntityLinkMixin, _CreateTransactionSplitMixin,
_CreateTransactionPickersMixin`. `part`/`part of` keeps all of these in one
library so the mixins and base class can share private (`_`-prefixed) fields,
which a normal cross-file mixin could not do.

This pattern is reserved for cases like this one, where a single State class
genuinely cannot be broken into independent widgets without major behavioral
restructuring. New unrelated functionality should still be extracted into
proper standalone files (sections/widgets/helpers) rather than added as a
fourth mixin.
