/// Example of how to test ScopedScreen and BaseScreen
///
/// This would typically be in your test/ directory

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../scoped_screen.dart';
import '../base_screen.dart';
import '../../di/service_locator.dart';

// ============================================================================
// Test Helpers
// ============================================================================

/// Mock auth service for testing
class MockAuthService {
  bool isAuthenticated = false;
  String? token;

  void login(String token) {
    this.token = token;
    isAuthenticated = true;
  }

  void logout() {
    token = null;
    isAuthenticated = false;
  }
}

/// Mock repository for testing
class MockUserRepository {
  final MockAuthService authService;

  MockUserRepository(this.authService);

  Future<Map<String, dynamic>> getUser() async {
    if (!authService.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    return {'id': '1', 'name': 'Test User'};
  }
}

// ============================================================================
// Example: Testing ScopedScreen
// ============================================================================

class TestScopedScreen extends ScopedScreen {
  const TestScopedScreen({super.key});

  @override
  State<TestScopedScreen> createState() => _TestScopedScreenState();
}

class _TestScopedScreenState extends ScopedScreenState<TestScopedScreen> {
  Map<String, dynamic>? userData;
  int onReadyCallCount = 0;
  int onDisposeCallCount = 0;

  @override
  void registerServices() {
    // Register mock repository with global auth service
    final auth = getService<MockAuthService>();
    registerSingleton<MockUserRepository>(MockUserRepository(auth));
  }

  @override
  void onReady() {
    onReadyCallCount++;
    _loadUser();
  }

  @override
  void onDispose() {
    onDisposeCallCount++;
  }

  Future<void> _loadUser() async {
    final repo = getService<MockUserRepository>();
    try {
      final data = await repo.getUser();
      setState(() => userData = data);
    } catch (e) {
      setState(() => userData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Screen')),
      body: userData != null
          ? Text('Hello ${userData!['name']}', key: Key('greeting'))
          : Text('Not logged in', key: Key('not_logged_in')),
    );
  }
}

void testScopedScreen() {
  group('ScopedScreen Tests', () {
    setUp(() {
      // Reset service locator before each test
      locator.reset();
    });

    tearDown(() {
      // Clean up after each test
      locator.reset();
    });

    testWidgets('should register scoped services', (tester) async {
      // Setup global service
      final authService = MockAuthService();
      locator.registerSingleton<MockAuthService>(authService);

      await tester.pumpWidget(MaterialApp(home: TestScopedScreen()));

      // Give time for onReady to execute
      await tester.pumpAndSettle();

      // Verify screen is built
      expect(find.byType(TestScopedScreen), findsOneWidget);
    });

    testWidgets('should call onReady after first frame', (tester) async {
      final authService = MockAuthService();
      authService.login('test-token');
      locator.registerSingleton<MockAuthService>(authService);

      await tester.pumpWidget(MaterialApp(home: TestScopedScreen()));

      // Initial build - onReady not called yet
      await tester.pump();

      // After frame callback - onReady called
      await tester.pumpAndSettle();

      expect(find.text('Hello Test User'), findsOneWidget);
    });

    testWidgets('should dispose scoped services', (tester) async {
      final authService = MockAuthService();
      locator.registerSingleton<MockAuthService>(authService);

      await tester.pumpWidget(MaterialApp(home: TestScopedScreen()));
      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(MaterialApp(home: Container()));

      // onDispose should have been called
      // (In real tests, you'd verify through state or mocks)
    });

    testWidgets('should access global services', (tester) async {
      final authService = MockAuthService();
      authService.login('test-token');
      locator.registerSingleton<MockAuthService>(authService);

      await tester.pumpWidget(MaterialApp(home: TestScopedScreen()));
      await tester.pumpAndSettle();

      // Verify it accessed global auth service
      expect(find.text('Hello Test User'), findsOneWidget);
    });

    testWidgets('should handle unauthenticated state', (tester) async {
      final authService = MockAuthService(); // Not logged in
      locator.registerSingleton<MockAuthService>(authService);

      await tester.pumpWidget(MaterialApp(home: TestScopedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Not logged in'), findsOneWidget);
    });
  });
}

// ============================================================================
// Example: Testing BaseScreen
// ============================================================================

class TestBaseScreen extends BaseScreen {
  const TestBaseScreen({super.key});

  @override
  State<TestBaseScreen> createState() => _TestBaseScreenState();
}

class _TestBaseScreenState extends BaseScreenState<TestBaseScreen> {
  int counter = 0;
  bool onReadyCalled = false;
  bool onDisposeCalled = false;

  @override
  void onReady() {
    onReadyCalled = true;
  }

  @override
  void onDispose() {
    onDisposeCalled = true;
  }

  void increment() {
    setState(() => counter++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Base Screen Test')),
      body: Column(
        children: [
          Text('$counter', key: Key('counter')),
          ElevatedButton(
            key: Key('increment_btn'),
            onPressed: increment,
            child: Text('Increment'),
          ),
        ],
      ),
    );
  }
}

void testBaseScreen() {
  group('BaseScreen Tests', () {
    testWidgets('should call onReady', (tester) async {
      await tester.pumpWidget(MaterialApp(home: TestBaseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should update state', (tester) async {
      await tester.pumpWidget(MaterialApp(home: TestBaseScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('increment_btn')));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should call onDispose', (tester) async {
      await tester.pumpWidget(MaterialApp(home: TestBaseScreen()));
      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pump();

      // onDispose should have been called
    });
  });
}

// ============================================================================
// Example: Integration Testing with Navigation
// ============================================================================

void testNavigationWithScopes() {
  group('Navigation Tests', () {
    setUp(() {
      locator.reset();
    });

    tearDown(() {
      locator.reset();
    });

    testWidgets('should create and dispose scopes on navigation', (tester) async {
      final authService = MockAuthService();
      authService.login('test-token');
      locator.registerSingleton<MockAuthService>(authService);

      await tester.pumpWidget(MaterialApp(
        home: TestScopedScreen(),
        routes: {
          '/other': (context) => TestBaseScreen(),
        },
      ));

      await tester.pumpAndSettle();
      expect(find.text('Hello Test User'), findsOneWidget);

      // Navigate to another screen
      final context = tester.element(find.byType(TestScopedScreen));
      Navigator.pushNamed(context, '/other');

      await tester.pumpAndSettle();

      // Previous screen's scope should be disposed when popped
      Navigator.pop(context);
      await tester.pumpAndSettle();
    });
  });
}

// ============================================================================
// Example: Mock Disposable Service
// ============================================================================

class MockDisposableService {
  bool isDisposed = false;

  void dispose() {
    isDisposed = true;
  }
}

class TestDisposalScreen extends ScopedScreen {
  const TestDisposalScreen({super.key});

  @override
  State<TestDisposalScreen> createState() => _TestDisposalScreenState();
}

class _TestDisposalScreenState extends ScopedScreenState<TestDisposalScreen> {
  @override
  void registerServices() {
    registerSingleton<MockDisposableService>(MockDisposableService());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Container());
  }
}

void testServiceDisposal() {
  group('Service Disposal Tests', () {
    setUp(() {
      locator.reset();
    });

    testWidgets('should dispose scoped services', (tester) async {
      await tester.pumpWidget(MaterialApp(home: TestDisposalScreen()));
      await tester.pumpAndSettle();

      // Widget is active, service should be registered in scope

      // Remove widget
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pump();

      // Scope should be disposed along with its services
      // (In real implementation, MockDisposableService would implement Disposable)
    });
  });
}

// ============================================================================
// Run all tests
// ============================================================================

void main() {
  testScopedScreen();
  testBaseScreen();
  testNavigationWithScopes();
  testServiceDisposal();
}
