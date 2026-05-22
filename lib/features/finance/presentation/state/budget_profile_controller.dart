import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/datasources/rest/budget_profile_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/models/budget_profile_model.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

class BudgetProfileController extends StreamState<AsyncState<List<BudgetProfile>>> {
  final BudgetProfileDataSourceRest _dataSource;

  String? selectedProfileId;

  /// Synchronous — reads from already-loaded state. Safe to call anytime.
  String? get activeProfileId {
    if (selectedProfileId != null) return selectedProfileId;
    final profiles = data;
    if (profiles == null || profiles.isEmpty) return null;
    try {
      return profiles.firstWhere((p) => p.isMain).id;
    } catch (_) {
      return profiles.first.id;
    }
  }

  BudgetProfileController(this._dataSource) : super(const AsyncLoading()) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    await execute(() async {
      final profiles = await _dataSource.getProfiles();
      if (selectedProfileId == null && profiles.isNotEmpty) {
        final main = profiles.firstWhere(
          (p) => p.isMain,
          orElse: () => profiles.first,
        );
        selectedProfileId = main.id;
      }
      return profiles;
    });
  }

  Future<void> createProfile(BudgetProfile profile) async {
    await executeSilent(() async {
      final created = await _dataSource.createProfile(BudgetProfileModel.fromEntity(profile));
      return [...(data ?? []), created];
    });
  }

  Future<void> updateProfile(BudgetProfile profile) async {
    await executeSilent(() async {
      final updated = await _dataSource.updateProfile(BudgetProfileModel.fromEntity(profile));
      return (data ?? []).map((p) => p.id == profile.id ? updated : p).toList();
    });
  }

  Future<void> deleteProfile(String id) async {
    await executeSilent(() async {
      await _dataSource.deleteProfile(id);
      return (data ?? []).where((p) => p.id != id).toList();
    });
  }

  Future<void> setAsMain(String id) async {
    await executeSilent(() async {
      final updated = await _dataSource.setAsMain(id);
      return (data ?? []).map((p) => p.id == id ? updated : p.copyWith(isMain: false)).toList();
    });
  }

  Future<List<Budget>> getBudgetsForProfile(String profileId) async {
    return _dataSource.getBudgetGroups(profileId);
  }
}
