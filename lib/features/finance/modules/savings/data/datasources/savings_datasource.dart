import '../models/savings_bucket_model.dart';

abstract class SavingsDataSource {
  Future<List<SavingsBucketModel>> getSavingsBuckets();
  Future<SavingsBucketModel> createSavingsBucket(SavingsBucketModel bucket);
  Future<SavingsBucketModel> updateSavingsBucket(SavingsBucketModel bucket);
  Future<void> deleteSavingsBucket(String id);
}
