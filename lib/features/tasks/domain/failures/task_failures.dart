/// Domain failures for task operations
/// These extend the core Failure class from core/error
library;

import '../../../../core/error/error.dart';

/// Task was not found
class TaskNotFoundFailure extends NotFoundFailure {
  TaskNotFoundFailure(String taskId)
      : super(
          resourceType: 'Task',
          resourceId: taskId,
          message: 'Task not found: $taskId',
        );
}

/// Task already completed - cannot perform operation
class TaskAlreadyCompletedFailure extends BusinessRuleFailure {
  TaskAlreadyCompletedFailure()
      : super(
          rule: 'Task is already completed',
          message: 'Cannot modify a completed task',
        );
}

/// Invalid task status transition
class InvalidTaskStatusTransitionFailure extends BusinessRuleFailure {
  final String from;
  final String to;

  InvalidTaskStatusTransitionFailure(this.from, this.to)
      : super(
          rule: 'Invalid status transition',
          message: 'Cannot transition from $from to $to',
        );
}

/// Task has dependencies that must be completed first
class TaskHasDependenciesFailure extends BusinessRuleFailure {
  final List<String> dependencyIds;

  TaskHasDependenciesFailure(this.dependencyIds)
      : super(
          rule: 'Task has uncompleted dependencies',
          message: 'Complete ${dependencyIds.length} dependent task(s) first',
        );
}

/// Project not found for task
class ProjectNotFoundForTaskFailure extends NotFoundFailure {
  ProjectNotFoundForTaskFailure(String projectId)
      : super(
          resourceType: 'Project',
          resourceId: projectId,
          message: 'Project not found: $projectId',
        );
}
