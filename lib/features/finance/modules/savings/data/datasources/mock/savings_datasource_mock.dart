import 'package:keep_track/features/finance/modules/savings/data/datasources/savings_datasource.dart';
import 'package:keep_track/features/finance/modules/savings/data/models/savings_bucket_model.dart';

final _buckets = <SavingsBucketModel>[
  SavingsBucketModel(id: 'savings-emergency', userId: 'demo', name: 'Emergency Fund', balance: 8500,  colorHex: '#4CAF50', iconCodePoint: '57571'),
  SavingsBucketModel(id: 'savings-travel',    userId: 'demo', name: 'Travel Fund',    balance: 2300,  colorHex: '#2196F3', iconCodePoint: '58130'),
  SavingsBucketModel(id: 'savings-laptop',    userId: 'demo', name: 'New Laptop',     balance: 1200,  colorHex: '#9C27B0', iconCodePoint: '57809'),
];

class SavingsDataSourceMock implements SavingsDataSource {
  @override
  Future<List<SavingsBucketModel>> getSavingsBuckets() async => _buckets;

  @override
  Future<SavingsBucketModel> createSavingsBucket(SavingsBucketModel bucket) async => bucket;

  @override
  Future<SavingsBucketModel> updateSavingsBucket(SavingsBucketModel bucket) async => bucket;

  @override
  Future<void> deleteSavingsBucket(String id) async {}
}
