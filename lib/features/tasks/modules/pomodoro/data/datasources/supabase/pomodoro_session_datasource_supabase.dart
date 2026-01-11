import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/pomodoro_session_model.dart';
import '../pomodoro_session_datasource.dart';
import '../../../../../../../shared/infrastructure/supabase/supabase_service.dart';

/// Supabase implementation of PomodoroSessionDataSource
class PomodoroSessionDataSourceSupabase implements PomodoroSessionDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'pomodoro_sessions';

  PomodoroSessionDataSourceSupabase(this.supabaseService);

  @override
  Future<List<PomodoroSessionModel>> getSessions(String userId) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false);

    return (response as List)
        .map(
          (doc) => PomodoroSessionModel.fromJson(doc as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<PomodoroSessionModel?> getActiveSession(String userId) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['running', 'paused']) // Include both running and paused
        .isFilter('ended_at', null)
        .order('started_at', ascending: false)
        .limit(1);

    if (response is List && response.isNotEmpty) {
      return PomodoroSessionModel.fromJson(response.first as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<PomodoroSessionModel?> getSessionById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null
        ? PomodoroSessionModel.fromJson(response as Map<String, dynamic>)
        : null;
  }

  @override
  Future<PomodoroSessionModel> createSession(
    PomodoroSessionModel session,
  ) async {
    final doc = session.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return PomodoroSessionModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<PomodoroSessionModel> updateSession(
    PomodoroSessionModel session,
  ) async {
    if (session.id == null) {
      throw Exception('Cannot update session without an ID');
    }

    final doc = session.toJson();
    doc.remove('id'); // Don't update the ID field

    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', session.id!)
        .select()
        .single();

    return PomodoroSessionModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSession(String id) async {
    await supabaseService.client.from(tableName).delete().eq('id', id);
  }

  @override
  Future<List<PomodoroSessionModel>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .gte('started_at', startDate.toIso8601String())
        .lte('started_at', endDate.toIso8601String())
        .order('started_at', ascending: false);

    return (response as List)
        .map(
          (doc) => PomodoroSessionModel.fromJson(doc as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<PomodoroSessionModel>> getSessionsByType(
    String userId,
    String type,
  ) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .eq('type', type)
        .order('started_at', ascending: false);

    return (response as List)
        .map(
          (doc) => PomodoroSessionModel.fromJson(doc as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<int> getCompletedSessionsCount(String userId) async {
    final response = await supabaseService.client
        .from(tableName)
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .count(CountOption.exact);

    return response.count ?? 0;
  }
}
