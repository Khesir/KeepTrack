# Architecture Overview

Personal Codex uses **Clean Architecture** with custom **Dependency Injection** and **Service Locator** patterns.

## Project Structure

```
lib/
├── core/                           # Core infrastructure
│   ├── di/                         # Dependency Injection system
│   │   ├── di_container.dart       # Core DI container
│   │   ├── service_locator.dart    # Global & scoped locators
│   │   ├── disposable.dart         # Disposal interface
│   │   ├── di_logger.dart          # Toggle logger
│   │   └── app_composition.dart    # App-level DI setup
│   └── ui/                         # UI base classes
│       ├── scoped_screen.dart      # Screen with scoping
│       └── base_screen.dart        # Screen without scoping
│
├── features/                       # Feature modules
│   └── tasks/                      # Task management feature
│       ├── domain/                 # Business logic
│       │   ├── entities/           # Domain models
│       │   └── repositories/       # Repository interfaces
│       ├── data/                   # Data layer
│       │   ├── models/             # DTOs
│       │   ├── datasources/        # Data source interfaces
│       │   │   └── mongodb/        # MongoDB implementation
│       │   └── repositories/       # Repository implementations
│       ├── presentation/           # UI layer
│       │   └── screens/            # Screen widgets
│       └── tasks_di.dart           # Feature DI setup
│
└── example_app.dart                # Example application
```

## Architecture Layers

### 1. Core Layer

**Purpose**: Shared infrastructure used across all features

**Components**:
- **DI System**: Custom dependency injection and service locator
- **UI Base Classes**: Reusable screen base classes with scope management
- **Common Utilities**: Shared utilities and helpers

**Key Files**:
- `core/di/service_locator.dart` - Global service locator
- `core/ui/scoped_screen.dart` - Base screen with automatic scope management

### 2. Feature Layer (Clean Architecture)

Each feature follows clean architecture with three sub-layers:

#### Domain Layer (Business Logic)
- **Entities**: Pure business models with no dependencies
- **Repository Interfaces**: Contracts for data access
- **Use Cases**: Business logic operations (optional)

**Rules**:
- No dependencies on outer layers
- Only business logic
- Framework-independent

**Example**:
```dart
// Domain entity
class Task {
  final String id;
  final String title;
  // ... business properties
}

// Repository interface
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task> createTask(Task task);
}
```

#### Data Layer
- **Models**: DTOs for database/API communication
- **Data Sources**: Abstract database operations
- **Repository Implementations**: Implements domain repository interfaces

**Rules**:
- Depends on domain layer
- Implements repository interfaces
- Converts between models and entities

**Example**:
```dart
// Model (DTO)
class TaskModel {
  final String id;
  final String title;

  Task toEntity() => Task(id: id, title: title);
  factory TaskModel.fromEntity(Task task) => ...
  Map<String, dynamic> toJson() => ...
  factory TaskModel.fromJson(Map json) => ...
}

// Repository implementation
class TaskRepositoryImpl implements TaskRepository {
  final TaskDataSource dataSource;

  @override
  Future<List<Task>> getTasks() async {
    final models = await dataSource.getTasks();
    return models.map((m) => m.toEntity()).toList();
  }
}
```

#### Presentation Layer
- **Screens**: UI widgets
- **State Management**: Screen state (using ScopedScreen pattern)
- **Widgets**: Reusable UI components

**Rules**:
- Depends on domain layer
- Uses repositories through DI
- No direct database access

**Example**:
```dart
class TaskListScreen extends ScopedScreen {
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  late TaskRepository _repository;

  @override
  void onReady() {
    _repository = getService<TaskRepository>();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _repository.getTasks();
    // Update UI
  }
}
```

## Dependency Flow

```
Presentation Layer
      ↓ (depends on)
Domain Layer (Interfaces)
      ↑ (implements)
Data Layer
```

- **Presentation** depends on **Domain** (interfaces only)
- **Data** implements **Domain** interfaces
- **Domain** has no dependencies (pure business logic)

## Design Patterns

### 1. Service Locator Pattern

Global access to services without BuildContext:

```dart
// Register
locator.registerSingleton<AuthService>(AuthService());

// Access anywhere
final auth = locator.get<AuthService>();
```

### 2. Repository Pattern

Abstraction between domain and data layers:

```dart
// Domain defines interface
abstract class TaskRepository {
  Future<List<Task>> getTasks();
}

// Data implements it
class TaskRepositoryImpl implements TaskRepository {
  final TaskDataSource dataSource;

  Future<List<Task>> getTasks() async {
    // Get from database
  }
}
```

### 3. Adapter Pattern

MongoDB service as database adapter:

```dart
// Abstract operations
abstract class TaskDataSource {
  Future<List<TaskModel>> getTasks();
}

// MongoDB implementation
class TaskDataSourceMongoDB implements TaskDataSource {
  final MongoDBService mongoService;

  Future<List<TaskModel>> getTasks() async {
    final docs = await mongoService.collection('tasks').find();
    return docs.map((doc) => TaskModel.fromJson(doc)).toList();
  }
}
```

### 4. Scoped Service Locator

Screen-specific service lifetime:

```dart
class ProfileScreen extends ScopedScreen {
  @override
  State createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
  @override
  void registerServices() {
    // Services only live while screen is active
    registerSingleton<ProfileCache>(ProfileCache());
  }

  @override
  void onDispose() {
    // Scope and all its services automatically disposed
  }
}
```

### 5. Disposable Pattern

Automatic resource cleanup:

```dart
class DatabaseService implements Disposable {
  @override
  void dispose() {
    // Close connections, release resources
  }
}

// Automatically disposed when unregistered
locator.unregister<DatabaseService>();
```

## Dependency Injection

### Registration

```dart
void setupDependencies() {
  // Singleton - created immediately
  locator.registerSingleton<AuthService>(AuthService());

  // Lazy singleton - created on first access
  locator.registerLazySingleton<Database>(() => Database());

  // Factory - new instance each time
  locator.registerFactory<TaskRepository>(() => TaskRepositoryImpl(
    dataSource: locator.get<TaskDataSource>(),
  ));
}
```

### Scoped Registration

```dart
class TaskListScreen extends ScopedScreen {
  // ...
}

class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  @override
  void registerServices() {
    // Only exists while screen is active
    registerSingleton<TaskListCache>(TaskListCache());
  }

  @override
  Widget build(BuildContext context) {
    // Access scoped service
    final cache = getService<TaskListCache>();

    // Or global service
    final repo = getService<TaskRepository>();

    return Container();
  }
}
```

## Data Flow Example

1. **User Action** → Button tap in UI
2. **Presentation** → Screen calls repository method
3. **Domain** → Repository interface defines contract
4. **Data** → Repository implementation uses data source
5. **Data Source** → MongoDB adapter queries database
6. **Response** → Models converted to entities
7. **UI Update** → Screen displays entities

```dart
// 1. User taps button
onPressed: () => _loadTasks();

// 2. Screen method
Future<void> _loadTasks() async {
  // 3. Call repository (domain interface)
  final tasks = await _repository.getTasks();

  // 7. Update UI
  setState(() => _tasks = tasks);
}

// 4. Repository implementation (data layer)
class TaskRepositoryImpl implements TaskRepository {
  Future<List<Task>> getTasks() async {
    // 5. Get from data source
    final models = await dataSource.getTasks();

    // 6. Convert to entities
    return models.map((m) => m.toEntity()).toList();
  }
}

// Data source MongoDB implementation
class TaskDataSourceMongoDB implements TaskDataSource {
  Future<List<TaskModel>> getTasks() async {
    // Query database
    final docs = await mongoService.collection('tasks').find();
    return docs.map((doc) => TaskModel.fromJson(doc)).toList();
  }
}
```

## Benefits

### Clean Architecture Benefits

1. **Independent of Frameworks** - Business logic doesn't depend on Flutter
2. **Testable** - Easy to test each layer independently
3. **Independent of UI** - Can swap UI without changing business logic
4. **Independent of Database** - Can swap MongoDB for SQLite/API
5. **Maintainable** - Changes isolated to specific layers

### Custom DI Benefits

1. **No BuildContext Needed** - Access services anywhere
2. **Simple & Direct** - No magic, full visibility
3. **Scoped Services** - Automatic screen-specific lifecycle
4. **Memory Safe** - Automatic disposal with Disposable interface
5. **Zero Dependencies** - No external packages

## Testing Strategy

### Unit Tests
```dart
// Test domain entities
test('Task should be overdue', () {
  final task = Task(
    dueDate: DateTime.now().subtract(Duration(days: 1)),
    status: TaskStatus.todo,
  );
  expect(task.isOverdue, true);
});
```

### Repository Tests
```dart
// Test with mock data source
test('Repository should return tasks', () async {
  final mockDataSource = MockTaskDataSource();
  final repository = TaskRepositoryImpl(mockDataSource);

  final tasks = await repository.getTasks();
  expect(tasks, isNotEmpty);
});
```

### Widget Tests
```dart
// Test screen with mock repository
testWidgets('Should display tasks', (tester) async {
  locator.registerSingleton<TaskRepository>(MockTaskRepository());

  await tester.pumpWidget(MaterialApp(home: TaskListScreen()));
  await tester.pumpAndSettle();

  expect(find.byType(TaskListScreen), findsOneWidget);
});
```

## Adding New Features

1. Create feature directory in `features/`
2. Create domain layer (entities, repositories)
3. Create data layer (models, data sources, repositories)
4. Create presentation layer (screens)
5. Create DI setup file
6. Register dependencies
7. Add to routing

## Best Practices

1. **Keep domain pure** - No framework dependencies
2. **Use repository pattern** - Abstract data access
3. **Implement Disposable** - For resources that need cleanup
4. **Use scoped services** - For screen-specific state
5. **Register in DI** - Make services injectable
6. **Follow naming conventions** - Clear, descriptive names
7. **Document public APIs** - Add doc comments
8. **Write tests** - Test each layer independently

## Resources

- `core/QUICK_START.md` - Quick reference guide
- `core/di/README.md` - DI system details
- `core/ui/README.md` - Screen base classes
- `features/tasks/README.md` - Task feature documentation
