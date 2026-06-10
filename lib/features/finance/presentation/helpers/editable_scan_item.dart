import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

class EditableScanItem {
  final String id;
  double amount;
  TransactionType type;
  String description;
  DateTime date;
  String categoryName;
  FinanceCategory? category;
  String? profileId;
  String? profileName;
  String? profileBaseName;
  bool isMonthlyProfile;
  bool included;

  // Entity linking
  String? entityType;   // "subscription" | "debt_payment" | "lending" | "goal" | null
  String? entityHint;   // AI-suggested name to pre-filter picker
  String? subscriptionId;
  String? debtId;
  String? goalId;
  String? entityLabel;  // display name of the linked entity

  // Wallet linking
  String? walletId;
  String? walletName;
  String? walletHint;   // AI-suggested wallet name hint

  EditableScanItem({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.categoryName,
    this.category,
    this.profileId,
    this.profileName,
    this.profileBaseName,
    this.isMonthlyProfile = false,
    this.included = true,
    this.entityType,
    this.entityHint,
    this.walletHint,
  });
}
