/// Custom state management for Personal Codex
///
/// Provides two lightweight, portable state management solutions:
///
/// 1. **StreamState** - Pure Dart streams-based state management
///    - Zero Flutter dependency in business logic
///    - Portable to non-Flutter Dart projects
///    - Broadcast streams for multiple listeners
///
/// 2. **NotifierState** - ChangeNotifier-based state management
///    - Lighter weight than StreamState
///    - Uses Flutter's optimized listener pattern
///    - Best for Flutter-only projects
///
/// Both support AsyncState<T> for automatic loading/error handling.
///
/// Example usage:
/// ```dart
/// // Create a controller
/// class TaskController extends StreamState<AsyncState<List<Task>>> {
///   final TaskRepository _repo;
///
///   TaskController(this._repo) : super(const AsyncLoading()) {
///     loadTasks();
///   }
///
///   Future<void> loadTasks() async {
///     await execute(() => _repo.getTasks());
///   }
/// }
///
/// // Use in UI
/// AsyncStreamBuilder<List<Task>>(
///   state: controller,
///   builder: (context, tasks) => TaskList(tasks),
/// )
/// ```
///
/// See QUICKSTART.md for detailed examples and patterns.
library;

// Core state classes
export 'stream_state.dart';
export 'stream_builder_widget.dart';
