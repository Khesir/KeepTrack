# Project-Task Relationship

## Overview

The relationship between Projects and Tasks:
- **Projects** can have multiple **Tasks**
- **Tasks** can optionally belong to a **Project**
- Tasks without a project are standalone tasks

## Domain Model

### Task Entity

```dart
class Task {
  final String? projectId;  // Optional - can be null
  // ... other fields
}
```

- `projectId` is optional (nullable)
- If `null`, task is standalone
- If set, task belongs to that project

### Project Entity

```dart
class Project {
  final String id;
  final String name;
  // ... other fields
  // Note: No tasks list - use repository methods instead
}
```

- Project doesn't store tasks directly
- Use `TaskRepository.getTasksByProject(projectId)` to get tasks
- Keeps entities clean and avoids circular dependencies

## Repository Methods

### TaskRepository

```dart
// Get all tasks for a project
Future<List<Task>> getTasksByProject(String projectId);

// Create task with project
final task = Task(
  id: '1',
  title: 'Task 1',
  projectId: 'project-1',  // Link to project
  // ...
);
await taskRepository.createTask(task);

// Create standalone task
final task = Task(
  id: '2',
  title: 'Task 2',
  projectId: null,  // No project
  // ...
);
await taskRepository.createTask(task);
```

### ProjectRepository

```dart
// Standard CRUD operations
Future<List<Project>> getProjects();
Future<Project> createProject(Project project);
Future<void> deleteProject(String id);
```

## UI Flow

### 1. View All Projects
**ProjectListScreen** → Shows all projects

### 2. View Project Details
**ProjectDetailScreen** → Shows project info + all its tasks
- Displays project name, description, color
- Shows task count and completion progress
- Lists all tasks belonging to this project
- Can create new tasks directly in this project

### 3. Create Task in Project
From **ProjectDetailScreen** → Tap FAB → **TaskDetailScreen**
- Pre-fills project selection with current project
- User can change project or set to "No Project"

### 4. View All Tasks
**TaskListScreen** → Shows all tasks (with or without projects)
- Can filter by status, priority, etc.
- Shows project association if exists

### 5. Create Standalone Task
From **TaskListScreen** → Tap FAB → **TaskDetailScreen**
- Project selector shows "No Project" by default
- User can optionally select a project

## Examples

### Create a Project with Tasks

```dart
// 1. Create project
final project = Project(
  id: 'proj-1',
  name: 'Mobile App',
  description: 'Build task management app',
  color: '#2196F3',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await projectRepository.createProject(project);

// 2. Create tasks for the project
final task1 = Task(
  id: 'task-1',
  title: 'Design UI',
  projectId: 'proj-1',  // Link to project
  status: TaskStatus.todo,
  priority: TaskPriority.high,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await taskRepository.createTask(task1);

final task2 = Task(
  id: 'task-2',
  title: 'Implement backend',
  projectId: 'proj-1',  // Link to same project
  status: TaskStatus.inProgress,
  priority: TaskPriority.high,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await taskRepository.createTask(task2);

// 3. Get all tasks for the project
final projectTasks = await taskRepository.getTasksByProject('proj-1');
// Returns [task1, task2]
```

### Create Standalone Task

```dart
final standaloneTask = Task(
  id: 'task-3',
  title: 'Buy groceries',
  projectId: null,  // No project
  status: TaskStatus.todo,
  priority: TaskPriority.low,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await taskRepository.createTask(standaloneTask);
```

### Move Task Between Projects

```dart
// Get task
final task = await taskRepository.getTaskById('task-1');

// Move to different project
final updated = task!.copyWith(
  projectId: 'proj-2',  // New project
  updatedAt: DateTime.now(),
);
await taskRepository.updateTask(updated);

// Or remove from project (make standalone)
final standalone = task.copyWith(
  projectId: null,  // Remove project
  updatedAt: DateTime.now(),
);
await taskRepository.updateTask(standalone);
```

## Screen Navigation Flow

```
ProjectListScreen
    ↓ Tap project
ProjectDetailScreen (shows project + its tasks)
    ↓ Tap FAB
TaskDetailScreen (project pre-selected)
    ↓ Save
Back to ProjectDetailScreen (refreshed)

---

TaskListScreen
    ↓ Tap FAB
TaskDetailScreen (no project selected)
    ↓ Select project (optional)
    ↓ Save
Back to TaskListScreen
```

## Data Flow

### Viewing Project Tasks

```
User taps project
    ↓
ProjectDetailScreen created
    ↓
onReady() called
    ↓
taskRepository.getTasksByProject(projectId)
    ↓
TaskRepositoryImpl → TaskDataSource
    ↓
MongoDB: collection.find({projectId: 'proj-1'})
    ↓
Return task models
    ↓
Convert to entities
    ↓
Display in UI
```

### Creating Task in Project

```
User taps FAB in ProjectDetailScreen
    ↓
Navigate to TaskDetailScreen(initialProjectId: project.id)
    ↓
Project pre-selected in dropdown
    ↓
User fills form
    ↓
taskRepository.createTask(task)
    ↓
TaskRepositoryImpl → TaskDataSource
    ↓
MongoDB: collection.insertOne({...task, projectId: 'proj-1'})
    ↓
Return to ProjectDetailScreen
    ↓
Refresh task list
```

## Business Rules

### Creating Projects
- ✅ Projects can be created without tasks
- ✅ Projects can have 0 to many tasks

### Creating Tasks
- ✅ Tasks can be created without a project
- ✅ Tasks can be assigned to a project at creation
- ✅ Tasks can be moved between projects
- ✅ Tasks can be removed from a project (becomes standalone)

### Deleting Projects
- ⚠️  Cannot delete project with tasks
- Must delete or reassign all tasks first
- Prevents orphaned tasks

### Archiving Projects
- ✅ Can archive projects with tasks
- Archived projects hidden from active list
- Tasks remain linked to archived project

## Database Schema

### Tasks Collection

```json
{
  "_id": "task-1",
  "title": "Design UI",
  "description": "Create mockups",
  "status": "todo",
  "priority": "high",
  "projectId": "proj-1",  // Can be null
  "tags": ["design", "ui"],
  "createdAt": "2024-12-14T10:00:00.000Z",
  "updatedAt": "2024-12-14T10:00:00.000Z",
  "dueDate": "2024-12-20T00:00:00.000Z",
  "completedAt": null
}
```

### Projects Collection

```json
{
  "_id": "proj-1",
  "name": "Mobile App",
  "description": "Build task management app",
  "color": "#2196F3",
  "createdAt": "2024-12-14T09:00:00.000Z",
  "updatedAt": "2024-12-14T09:00:00.000Z",
  "isArchived": false
}
```

## Benefits of This Design

1. **Optional Relationship** - Tasks can exist without projects
2. **Clean Entities** - No circular dependencies
3. **Flexible** - Easy to move tasks between projects
4. **Scalable** - Projects can have many tasks without loading all at once
5. **Simple Queries** - Easy to filter tasks by project
6. **Clear Separation** - Domain logic separated from data access

## Common Queries

```dart
// All tasks
final allTasks = await taskRepository.getTasks();

// Tasks for specific project
final projectTasks = await taskRepository.getTasksByProject('proj-1');

// Standalone tasks (no project)
final standaloneTasks = await taskRepository.getTasksFiltered(
  projectId: null,  // MongoDB will match null projectId
);

// Tasks for multiple projects (custom query)
// Would need to add method to repository/datasource
```

## Future Enhancements

- [ ] Cascade delete option (delete project + all tasks)
- [ ] Move all tasks when archiving project
- [ ] Project templates (create project with predefined tasks)
- [ ] Task templates within projects
- [ ] Project progress tracking
- [ ] Project statistics (completion rate, overdue tasks, etc.)
