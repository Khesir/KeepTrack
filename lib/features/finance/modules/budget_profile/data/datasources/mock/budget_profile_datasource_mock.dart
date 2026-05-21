import 'package:keep_track/features/finance/modules/budget/data/models/budget_model.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/datasources/rest/budget_profile_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/models/budget_profile_model.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

final _profiles = <BudgetProfileModel>[
  BudgetProfileModel(
    id: 'profile-personal',
    name: 'Personal',
    description: 'My personal budget',
    status: BudgetProfileStatus.active,
    profileType: BudgetProfileType.monthly,
    isMain: true,
    userId: 'demo',
    colorHex: '#2196F3',
  ),
  BudgetProfileModel(
    id: 'profile-side',
    name: 'Side Hustle',
    description: 'Freelance income & expenses',
    status: BudgetProfileStatus.active,
    profileType: BudgetProfileType.custom,
    isMain: false,
    userId: 'demo',
    colorHex: '#4CAF50',
  ),
];

class BudgetProfileDataSourceMock extends BudgetProfileDataSourceRest {
  @override
  Future<List<BudgetProfileModel>> getProfiles() async => _profiles;

  @override
  Future<BudgetProfileModel> createProfile(BudgetProfileModel profile) async => profile;

  @override
  Future<BudgetProfileModel> updateProfile(BudgetProfileModel profile) async => profile;

  @override
  Future<void> deleteProfile(String id) async {}

  @override
  Future<BudgetProfileModel> setAsMain(String id) async =>
      _profiles.firstWhere((p) => p.id == id);

  @override
  Future<List<BudgetModel>> getBudgetGroups(String profileId) async => [];
}
