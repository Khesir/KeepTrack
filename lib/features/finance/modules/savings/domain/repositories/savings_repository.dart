import 'package:keep_track/core/error/result.dart';
import '../entities/savings_bucket.dart';

abstract class SavingsRepository {
  Future<Result<List<SavingsBucket>>> getSavingsBuckets();
  Future<Result<SavingsBucket>> createSavingsBucket(SavingsBucket bucket);
  Future<Result<SavingsBucket>> updateSavingsBucket(SavingsBucket bucket);
  Future<Result<void>> deleteSavingsBucket(String id);
}
