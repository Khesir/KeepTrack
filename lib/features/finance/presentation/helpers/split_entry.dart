import 'package:flutter/material.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:uuid/uuid.dart';

class SplitEntry {
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();
  TransactionType type;
  FinanceCategory? category;
  DateTime date = DateTime.now();
  String? profileId;
  String? profileName;
  String? walletId;
  String? walletName;
  String? entityType; // "debt_payment" | "lending" | "goal" | "subscription"
  String? entityLabel;
  String? debtId;
  String? goalId;
  String? subscriptionId;

  bool isPlan = false;
  List<String> imagePaths = [];
  final String id = const Uuid().v4();

  SplitEntry({required this.type});

  double get amount => double.tryParse(amountCtrl.text) ?? 0;
  bool get isValid =>
      amount > 0 && (isPlan || category != null || entityType != null);

  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
  }
}
