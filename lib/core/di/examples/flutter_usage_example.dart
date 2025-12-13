import 'package:flutter/material.dart';
import '../service_locator.dart';
import '../di_logger.dart';
import 'example_services.dart';

/// Example: How to set up DI in a Flutter app
void setupDependencies() {
  // Enable logging in debug mode only
  // DILogger.enable();

  // Core services
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerLazySingleton<DatabaseService>(() {
    final db = DatabaseService();
    db.connect();
    return db;
  });
  locator.registerSingleton<FileStorageService>(FileStorageService());

  // Repositories
  locator.registerFactory<UserRepository>(
    () => UserRepository(
      authService: locator.get<AuthService>(),
      databaseService: locator.get<DatabaseService>(),
    ),
  );

  // Use cases
  locator.registerFactory<LoginUseCase>(
    () => LoginUseCase(repository: locator.get<UserRepository>()),
  );
}

/// Example: Main app entry point
void main() {
  setupDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'DI Example', home: LoginPage());
  }
}

/// Example: Using DI in a StatelessWidget
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleLogin(context),
          child: Text('Login'),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    // Get use case from service locator
    final loginUseCase = locator.get<LoginUseCase>();

    try {
      final user = await loginUseCase.execute('test@example.com', 'password');

      // Navigate to home page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: user)),
      );
    } catch (e) {
      // Handle error
      print('Login failed: $e');
    }
  }
}

/// Example: Using scoped services with StatefulWidget
class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScopedServiceLocator _scope;

  @override
  void initState() {
    super.initState();

    // Create a scope for this page
    _scope = locator.createScope(name: 'HomePage');

    // Register page-specific services
    _scope.registerSingleton<FileStorageService>(FileStorageService());
  }

  @override
  void dispose() {
    // Dispose the scope when page is disposed
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - ${widget.user.name}'),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome ${widget.user.name}!'),
            ElevatedButton(
              onPressed: _loadUserData,
              child: Text('Load User Data'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadUserData() {
    // Use scoped service
    final fileStorage = _scope.get<FileStorageService>();
    fileStorage.openFile('user_data.json');

    // Can still access global services
    final authService = _scope.get<AuthService>();
    print('Token: ${authService.token}');
  }

  void _handleLogout() {
    // Get auth service and logout
    final authService = locator.get<AuthService>();
    authService.logout();

    // Go back to login
    Navigator.pop(context);
  }
}

/// Example: Using DI in a custom widget
class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Access services directly
    final authService = locator.get<AuthService>();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Auth Status: ${authService.isAuthenticated ? "Logged In" : "Logged Out"}',
          ),
          if (authService.isAuthenticated) Text('Token: ${authService.token}'),
        ],
      ),
    );
  }
}

/// Example: Clean up when app is terminating
class MyAppWithCleanup extends StatefulWidget {
  const MyAppWithCleanup({super.key});

  @override
  _MyAppWithCleanupState createState() => _MyAppWithCleanupState();
}

class _MyAppWithCleanupState extends State<MyAppWithCleanup>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is being terminated, clean up services
      locator.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'DI Example', home: LoginPage());
  }
}
