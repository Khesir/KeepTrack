import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/features/tasks/modules/tasks/domain/repositories/task_repository.dart';

/// Controller for managing task activity state
class TaskActivityController extends StreamState<AsyncState<Map<DateTime, int>>> {
  final TaskRepository _taskRepository;

  TaskActivityController(this._taskRepository) : super(const AsyncLoading());

  /// Load task activity for the last N months
  Future<void> loadTaskActivity(int months) async {
    await execute(() async {
      return await _taskRepository
          .getTaskActivityForLastMonths(months)
          .then((r) => r.unwrap());
    });
  }
}
