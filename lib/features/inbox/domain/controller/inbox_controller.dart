import 'dart:convert';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/features/inbox/domain/entities/announcement.dart';
import 'package:keep_track/features/inbox/domain/repository/announcement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxController extends StreamState<AsyncState<List<Announcement>>> {
  final AnnouncementRepository _repository;
  final SharedPreferences _prefs;

  static const _readIdsKey = 'inbox_read_ids';
  Set<String> _readIds = {};

  InboxController(this._repository, this._prefs)
      : super(const AsyncLoading()) {
    _loadReadIds();
    load();
  }

  void _loadReadIds() {
    final raw = _prefs.getString(_readIdsKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _readIds = list.cast<String>().toSet();
    }
  }

  Future<void> load() async {
    try {
      emit(const AsyncLoading());
      final announcements = await _repository.fetchAll();
      emit(AsyncData(announcements));
    } catch (e) {
      emit(AsyncError('Failed to load announcements', e));
    }
  }

  bool isRead(String id) => _readIds.contains(id);

  int get unreadCount {
    final s = state;
    if (s is! AsyncData<List<Announcement>>) return 0;
    return s.data.where((a) => !_readIds.contains(a.id)).length;
  }

  Future<void> markAsRead(String id) async {
    if (_readIds.contains(id)) return;
    _readIds = {..._readIds, id};
    await _prefs.setString(_readIdsKey, jsonEncode(_readIds.toList()));
    emit(state);
  }

  Future<void> markAllAsRead() async {
    final s = state;
    if (s is! AsyncData<List<Announcement>>) return;
    _readIds = s.data.map((a) => a.id).toSet();
    await _prefs.setString(_readIdsKey, jsonEncode(_readIds.toList()));
    emit(state);
  }
}
