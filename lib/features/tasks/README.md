# Task Management Feature

Task and project management with MongoDB support, built using clean architecture.

## Architecture

```
features/tasks/
├── domain/                      # Business logic layer
│   ├── entities/                # Pure domain models
│   │   ├── task.dart
│   │   └── project.dart
│   └── repositories/            # Repository interfaces
│       ├── task_repository.dart
│       └── project_repository.dart
│
├── data/                        # Data layer
│   ├── models/                  # Data transfer objects
│   │   ├── task_model.dart
│   │   └── project_model.dart
│   ├── datasources/             # Data source interfaces & implementations
│   │   ├── task_datasource.dart
│   │   ├── project_datasource.dart
│   │   └── mongodb/
│   │       ├── mongodb_service.dart
│   │       ├── task_datasource_mongodb.dart
│   │       └── project_datasource_mongodb.dart
│   └── repositories/            # Repository implementations
│       ├── task_repository_impl.dart
│       └── project_repository_impl.dart
│
├── presentation/                # UI layer
│   └── screens/
│       ├── task_list_screen.dart
│       ├── task_detail_screen.dart
│       └── project_list_screen.dart
│
├── tasks_di.dart                # Dependency injection setup
└── tasks.dart                   # Barrel export
```

## Layers Explained

### Domain Layer (Business Logic)

**Entities** - Pure business models with no dependencies:
- `Task` - Task entity with status, priority, due dates
- `Project` - Project entity for organizing tasks

**Repository Interfaces** - Contracts for data access:
- `TaskRepository` - Defines task data operations
- `ProjectRepository` - Defines project data operations

### Data Layer

**Models** - DTOs for database communication:
- `TaskModel` - Converts between Task entity and database format
- `ProjectModel` - Converts between Project entity and database format

**Data Sources** - Abstract database operations:
- `TaskDataSource` - Interface for task database operations
- `ProjectDataSource` - Interface for project database operations
- `TaskDataSourceMongoDB` - MongoDB implementation for tasks
- `ProjectDataSourceMongoDB` - MongoDB implementation for projects

**MongoDB Service** - Database adapter:
- `MongoDBService` - Manages MongoDB connection
- `MongoCollection` - Provides CRUD operations
- In-memory implementation (can be replaced with real MongoDB)

**Repository Implementations** - Implements domain repository interfaces:
- `TaskRepositoryImpl` - Uses TaskDataSource
- `ProjectRepositoryImpl` - Uses ProjectDataSource

### Presentation Layer

**Screens**:
- `TaskListScreen` - View all tasks with filters
- `TaskDetailScreen` - Create/edit tasks
- `ProjectListScreen` - View and manage projects

## Usage

### 1. Setup Dependencies

```dart
import 'features/tasks/tasks_di.dart';

void main() {
  setupTasksDependencies();
  runApp(MyApp());
}
```

### 2. Use in Your App

```dart
import 'features/tasks/tasks.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TaskListScreen(),
    );
  }
}
```

### 3. Access Repositories

```dart
// In your screens
final taskRepository = locator.get<TaskRepository>();

// Load tasks
final tasks = await taskRepository.getTasks();

// Create task
final newTask = Task(
  id: '1',
  title: 'New Task',
  status: TaskStatus.todo,
  priority: TaskPriority.high,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await taskRepository.createTask(newTask);
```

## Features

### Task Management

- ✅ Create, read, update, delete tasks
- ✅ Task status (To Do, In Progress, Completed, Cancelled)
- ✅ Task priority (Low, Medium, High, Urgent)
- ✅ Due dates with overdue detection
- ✅ Tags for organization
- ✅ Search tasks
- ✅ Filter tasks by status, priority, project, tags

### Project Management

- ✅ Create, read, update, delete projects
- ✅ Project colors
- ✅ Archive/unarchive projects
- ✅ Link tasks to projects

### Database

- ✅ MongoDB adapter pattern
- ✅ In-memory implementation (for development)
- ✅ Easy to swap with real MongoDB
- ✅ Repository pattern for abstraction

## Domain Entities

### Task

```dart
Task(
  id: '1',
  title: 'Complete project',
  description: 'Finish the task management feature',
  status: TaskStatus.inProgress,
  priority: TaskPriority.high,
  projectId: 'project-1',
  tags: ['development', 'urgent'],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  dueDate: DateTime(2024, 12, 31),
);
```

**Properties:**
- `id` - Unique identifier
- `title` - Task title
- `description` - Optional description
- `status` - TaskStatus enum
- `priority` - TaskPriority enum
- `projectId` - Optional project ID
- `tags` - List of tags
- `createdAt` - Creation timestamp
- `updatedAt` - Last update timestamp
- `dueDate` - Optional due date
- `completedAt` - Completion timestamp

**Methods:**
- `copyWith()` - Create modified copy
- `isCompleted` - Check if completed
- `isOverdue` - Check if past due date

### Project

```dart
Project(
  id: '1',
  name: 'Personal App',
  description: 'Personal productivity app',
  color: '#2196F3',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  isArchived: false,
);
```

## Repository Pattern

The repository pattern provides abstraction between domain and data layers:

```dart
// Domain defines the interface
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task> createTask(Task task);
  // ... more methods
}

// Data layer implements it
class TaskRepositoryImpl implements TaskRepository {
  final TaskDataSource dataSource;

  @override
  Future<List<Task>> getTasks() async {
    final models = await dataSource.getTasks();
    return models.map((m) => m.toEntity()).toList();
  }
}
```

**Benefits:**
- Domain layer doesn't depend on data implementation
- Easy to swap data sources (MongoDB → SQLite → API)
- Testable with mock implementations

## Adapter Pattern (MongoDB)

The MongoDB service is an adapter that can be replaced:

```dart
// Current: In-memory implementation
class MongoDBService {
  final Map<String, List<Map<String, dynamic>>> _collections = {};
  // ... in-memory operations
}

// Future: Real MongoDB
class MongoDBService {
  late Db _db;

  Future<void> connect() async {
    _db = await Db.create(connectionString);
    await _db.open();
  }

  MongoCollection collection(String name) {
    return _db.collection(name);
  }
}
```

## Extending the Feature

### Add a New Entity

1. Create entity in `domain/entities/`
2. Create model in `data/models/`
3. Create repository interface in `domain/repositories/`
4. Create data source interface in `data/datasources/`
5. Create MongoDB implementation
6. Create repository implementation
7. Register in DI

### Add New Data Source (e.g., SQLite)

1. Create `data/datasources/sqlite/`
2. Implement `TaskDataSource` with SQLite
3. Implement `ProjectDataSource` with SQLite
4. Update DI registration to use SQLite instead

### Add Use Cases

Create use cases in `domain/usecases/`:

```dart
class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<Task> execute(String title, TaskPriority priority) async {
    final task = Task(
      id: generateId(),
      title: title,
      priority: priority,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return repository.createTask(task);
  }
}
```

## Testing

### Mock Repository

```dart
class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];

  @override
  Future<List<Task>> getTasks() async => _tasks;

  @override
  Future<Task> createTask(Task task) async {
    _tasks.add(task);
    return task;
  }
}

// In tests
locator.registerSingleton<TaskRepository>(MockTaskRepository());
```

### Test Screen

```dart
testWidgets('should display tasks', (tester) async {
  final mockRepo = MockTaskRepository();
  locator.registerSingleton<TaskRepository>(mockRepo);

  await tester.pumpWidget(MaterialApp(home: TaskListScreen()));
  await tester.pumpAndSettle();

  expect(find.byType(TaskListScreen), findsOneWidget);
});
```

## Clean Architecture Benefits

1. **Separation of Concerns** - Each layer has single responsibility
2. **Testability** - Easy to mock dependencies
3. **Flexibility** - Swap implementations without changing business logic
4. **Maintainability** - Changes isolated to specific layers
5. **Scalability** - Easy to extend with new features

## Next Steps

- [ ] Add real MongoDB integration
- [ ] Implement use cases layer
- [ ] Add state management (BLoC/Cubit)
- [ ] Add offline support
- [ ] Add synchronization
- [ ] Add task recurrence
- [ ] Add task subtasks
- [ ] Add task attachments
- [ ] Add collaboration features
