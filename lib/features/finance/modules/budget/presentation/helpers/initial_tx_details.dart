import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class InitialTxDetails {
  final Wallet wallet;
  final String? categoryId;
  final String? budgetProfileId;
  final List<String> imagePaths;

  const InitialTxDetails({
    required this.wallet,
    this.categoryId,
    this.budgetProfileId,
    this.imagePaths = const [],
  });
}
