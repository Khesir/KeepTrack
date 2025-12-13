/// Example of how to test with the DI system
///
/// This would typically be in your test/ directory
library;

import '../service_locator.dart';
import '../di_logger.dart';
import 'example_services.dart';

// Mock services for testing
class MockAuthService extends AuthService {
  bool _shouldSucceed = true;

  void setLoginResult(bool shouldSucceed) {
    _shouldSucceed = shouldSucceed;
  }

  @override
  Future<void> login(String email, String password) async {
    if (_shouldSucceed) {
      await super.login(email, password);
    } else {
      throw Exception('Login failed');
    }
  }
}

class MockDatabaseService extends DatabaseService {
  final List<String> _queries = [];

  @override
  void query(String sql) {
    _queries.add(sql);
    // Don't actually execute query
  }

  List<String> get executedQueries => _queries;
}

void main() {
  testLoginUseCase();
  testWithScope();
}

void testLoginUseCase() {
  print('\n=== Testing LoginUseCase ===\n');

  // Setup - reset before each test
  locator.reset();

  // Register mock services
  final mockAuth = MockAuthService();
  final mockDb = MockDatabaseService();

  locator.registerSingleton<AuthService>(mockAuth);
  locator.registerSingleton<DatabaseService>(mockDb);

  locator.registerFactory<UserRepository>(
    () => UserRepository(
      authService: locator.get<AuthService>(),
      databaseService: locator.get<DatabaseService>(),
    ),
  );

  locator.registerFactory<LoginUseCase>(
    () => LoginUseCase(repository: locator.get<UserRepository>()),
  );

  // Test successful login
  print('Test 1: Successful login');
  mockAuth.setLoginResult(true);

  final loginUseCase = locator.get<LoginUseCase>();
  loginUseCase
      .execute('test@example.com', 'password')
      .then((user) {
        print('✅ Login successful: ${user.name}');
        print('Database queries executed: ${mockDb.executedQueries.length}');
      })
      .catchError((error) {
        print('❌ Login failed: $error');
      });

  // Test failed login
  print('\nTest 2: Failed login');
  mockAuth.setLoginResult(false);

  loginUseCase
      .execute('test@example.com', 'wrong')
      .then((user) {
        print('❌ Should have failed but succeeded');
      })
      .catchError((error) {
        print('✅ Login correctly failed: $error');
      });

  // Cleanup
  locator.reset();
}

void testWithScope() {
  print('\n=== Testing Scoped Services ===\n');

  // Setup global services
  locator.registerSingleton<AuthService>(MockAuthService());

  // Create a test scope
  final scope = locator.createScope(name: 'TestScope');

  // Register scoped services
  final scopedFileService = FileStorageService();
  scope.registerSingleton<FileStorageService>(scopedFileService);

  // Test scoped service access
  print('Test: Access scoped service');
  final fileService = scope.get<FileStorageService>();
  fileService.openFile('test.txt');
  print('✅ Scoped service accessed successfully');

  // Test global service access from scope
  print('\nTest: Access global service from scope');
  final auth = scope.get<AuthService>();
  print('✅ Global service accessed from scope: ${auth.runtimeType}');

  // Test scope disposal
  print('\nTest: Dispose scope');
  scope.dispose();
  print('✅ Scope disposed');

  // Try to use after disposal (should throw)
  try {
    scope.get<FileStorageService>();
    print('❌ Should have thrown after disposal');
  } catch (e) {
    print('✅ Correctly threw after disposal: $e');
  }

  // Cleanup
  locator.reset();
}

/// Example: Integration test setup
class TestSetup {
  static void setupTestDependencies() {
    // Enable logging for tests
    DILogger.enable();

    // Reset to clean state
    locator.reset();

    // Register mock services
    locator.registerSingleton<AuthService>(MockAuthService());
    locator.registerSingleton<DatabaseService>(MockDatabaseService());

    // Register real implementations that depend on mocks
    locator.registerFactory<UserRepository>(
      () => UserRepository(
        authService: locator.get<AuthService>(),
        databaseService: locator.get<DatabaseService>(),
      ),
    );

    locator.registerFactory<LoginUseCase>(
      () => LoginUseCase(repository: locator.get<UserRepository>()),
    );
  }

  static void tearDown() {
    locator.reset();
    DILogger.disable();
  }
}

/// Example test structure
void exampleTestStructure() {
  // Before all tests
  TestSetup.setupTestDependencies();

  // Individual test
  test('should login successfully', () async {
    final loginUseCase = locator.get<LoginUseCase>();
    final user = await loginUseCase.execute('test@example.com', 'password');

    assert(user.id == '1');
    assert(user.name == 'John Doe');
  });

  // After all tests
  TestSetup.tearDown();
}

// Mock test function (replace with actual test framework)
void test(String description, Function() testFn) {
  print('\nTest: $description');
  try {
    testFn();
    print('✅ Passed');
  } catch (e) {
    print('❌ Failed: $e');
  }
}
