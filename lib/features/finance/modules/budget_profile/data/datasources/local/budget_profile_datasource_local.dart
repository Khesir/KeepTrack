import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_model.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/datasources/rest/budget_profile_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/models/budget_profile_model.dart';
import 'package:uuid/uuid.dart';

class BudgetProfileDataSourceLocal extends BudgetProfileDataSourceRest {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'budget_profiles';

  BudgetProfileDataSourceLocal(this._cache);

  Future<List<BudgetProfileModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => BudgetProfileModel.fromJson(e)).toList();
  }

  Future<List<BudgetProfileModel>> getProfiles() async {
    return _getAll();
  }

  Future<BudgetProfileModel> createProfile(BudgetProfileModel profile) async {
    final id = profile.id ?? _uuid.v4();
    final model = BudgetProfileModel.fromJson({...profile.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  Future<BudgetProfileModel> updateProfile(BudgetProfileModel profile) async {
    await _cache.put(_box, profile.id!, profile.toJson());
    return profile;
  }

  Future<void> deleteProfile(String id) async {
    await _cache.delete(_box, id);
  }

  Future<BudgetProfileModel> setAsMain(String id) async {
    final all = await _getAll();
    for (final p in all) {
      final updated =
          BudgetProfileModel.fromJson({...p.toJson(), 'isMain': p.id == id});
      await _cache.put(_box, p.id!, updated.toJson());
    }
    final data = await _cache.get(_box, id);
    return BudgetProfileModel.fromJson(data!);
  }

  Future<List<BudgetModel>> getBudgetGroups(String profileId) async {
    return [];
  }
}
