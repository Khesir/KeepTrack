import 'package:keep_track/features/finance/modules/subscriptions/data/datasources/subscription_datasource.dart';
import 'package:keep_track/features/finance/modules/subscriptions/data/models/subscription_model.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';

final _subscriptions = <SubscriptionModel>[
  SubscriptionModel(id: 'sub-netflix', userId: 'demo', name: 'Netflix',    provider: 'Netflix',    amount: 15.99, billingCycle: BillingCycle.monthly,  nextBillingDate: DateTime(2026, 6,  1), colorHex: '#E50914', iconCodePoint: '59354'),
  SubscriptionModel(id: 'sub-spotify', userId: 'demo', name: 'Spotify',    provider: 'Spotify',    amount: 9.99,  billingCycle: BillingCycle.monthly,  nextBillingDate: DateTime(2026, 6,  5), colorHex: '#1DB954', iconCodePoint: '59771'),
  SubscriptionModel(id: 'sub-adobe',   userId: 'demo', name: 'Adobe CC',   provider: 'Adobe',      amount: 54.99, billingCycle: BillingCycle.monthly,  nextBillingDate: DateTime(2026, 6,  3), colorHex: '#FF0000', iconCodePoint: '57809'),
  SubscriptionModel(id: 'sub-icloud',  userId: 'demo', name: 'iCloud+',    provider: 'Apple',      amount: 2.99,  billingCycle: BillingCycle.monthly,  nextBillingDate: DateTime(2026, 6,  8), colorHex: '#007AFF', iconCodePoint: '57813'),
  SubscriptionModel(id: 'sub-notion',  userId: 'demo', name: 'Notion',     provider: 'Notion',     amount: 10.00, billingCycle: BillingCycle.monthly,  nextBillingDate: DateTime(2026, 6, 12), colorHex: '#000000', iconCodePoint: '57534'),
  SubscriptionModel(id: 'sub-gym',     userId: 'demo', name: 'Gym',        provider: 'Fitness First', amount: 45.00, billingCycle: BillingCycle.monthly, nextBillingDate: DateTime(2026, 6,  1), colorHex: '#FF5722', iconCodePoint: '58794'),
];

class SubscriptionDataSourceMock implements SubscriptionDataSource {
  @override
  Future<List<SubscriptionModel>> getSubscriptions({String? budgetProfileId}) async => _subscriptions;

  @override
  Future<SubscriptionModel> createSubscription(SubscriptionModel subscription) async => subscription;

  @override
  Future<SubscriptionModel> updateSubscription(SubscriptionModel subscription) async => subscription;

  @override
  Future<void> deleteSubscription(String id) async {}

  @override
  Future<SubscriptionModel> pay(String id, {String? budgetId}) async =>
      _subscriptions.firstWhere((s) => s.id == id);
}
