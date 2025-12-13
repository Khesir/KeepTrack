/// Complete Flutter App Example
///
/// This shows how to integrate:
/// - DI Container & Service Locator
/// - ScopedScreen & BaseScreen
/// - Clean Architecture (Data, Domain, Presentation)
/// - Navigation
/// - Memory Management

import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../di/di_logger.dart';
import '../di/disposable.dart';
import '../ui/scoped_screen.dart';
import '../ui/base_screen.dart';

// ============================================================================
// DOMAIN LAYER
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

// ============================================================================
// DATA LAYER
// ============================================================================

/// Core Services
class AuthService {
  String? _token;

  Future<void> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 500));
    _token = 'token_${DateTime.now().millisecondsSinceEpoch}';
  }

  void logout() {
    _token = null;
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
}

class ApiClient {
  final AuthService authService;

  ApiClient(this.authService);

  Future<Map<String, dynamic>> get(String endpoint) async {
    if (!authService.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    await Future.delayed(Duration(milliseconds: 300));
    return {'data': 'mock_data'};
  }
}

/// Repositories
class UserRepository {
  final ApiClient apiClient;

  UserRepository(this.apiClient);

  Future<User> getCurrentUser() async {
    final response = await apiClient.get('/user/me');
    return User(id: '1', name: 'John Doe', email: 'john@example.com');
  }

  Future<List<User>> getUsers() async {
    await apiClient.get('/users');
    return [
      User(id: '1', name: 'John Doe', email: 'john@example.com'),
      User(id: '2', name: 'Jane Smith', email: 'jane@example.com'),
    ];
  }
}

// ============================================================================
// DOMAIN LAYER - USE CASES
// ============================================================================

class LoginUseCase {
  final AuthService authService;
  final UserRepository userRepository;

  LoginUseCase({
    required this.authService,
    required this.userRepository,
  });

  Future<User> execute(String email, String password) async {
    await authService.login(email, password);
    return userRepository.getCurrentUser();
  }
}

class LogoutUseCase {
  final AuthService authService;

  LogoutUseCase(this.authService);

  void execute() {
    authService.logout();
  }
}

class GetUsersUseCase {
  final UserRepository userRepository;

  GetUsersUseCase(this.userRepository);

  Future<List<User>> execute() {
    return userRepository.getUsers();
  }
}

// ============================================================================
// PRESENTATION LAYER - SCREENS
// ============================================================================

/// Login Screen - ScopedScreen with form management
class LoginScreen extends ScopedScreen {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ScopedScreenState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void registerServices() {
    // Login screen doesn't need scoped services
    // Uses global services via getService
  }

  @override
  void onDispose() {
    _emailController.dispose();
    _passwordController.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final loginUseCase = getService<LoginUseCase>();
      final user = await loginUseCase.execute(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Screen - ScopedScreen with scoped cache
class HomeScreen extends ScopedScreen {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ScopedScreenState<HomeScreen> {
  @override
  void registerServices() {
    // Register screen-specific cache
    registerSingleton<HomeCache>(HomeCache());
  }

  @override
  void onReady() {
    print('Home screen ready for user: ${widget.user.name}');
  }

  @override
  void onDispose() {
    print('Home screen disposing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - ${widget.user.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${widget.user.name}!',
                style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserListScreen()),
                );
              },
              child: Text('View Users'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    final logoutUseCase = getService<LogoutUseCase>();
    logoutUseCase.execute();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

class HomeCache implements Disposable {
  final Map<String, dynamic> _cache = {};

  void set(String key, dynamic value) => _cache[key] = value;
  dynamic get(String key) => _cache[key];

  @override
  void dispose() {
    _cache.clear();
    print('HomeCache disposed');
  }
}

/// User List Screen - With scoped list cache
class UserListScreen extends ScopedScreen {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ScopedScreenState<UserListScreen> {
  List<User>? _users;
  bool _isLoading = false;

  @override
  void registerServices() {
    registerSingleton<UserListCache>(UserListCache());
  }

  @override
  void onReady() {
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final cache = getService<UserListCache>();
      var users = cache.getUsers();

      if (users == null) {
        final getUsersUseCase = getService<GetUsersUseCase>();
        users = await getUsersUseCase.execute();
        cache.setUsers(users);
      }

      setState(() => _users = users);
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _users != null
              ? ListView.builder(
                  itemCount: _users!.length,
                  itemBuilder: (context, index) {
                    final user = _users![index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    );
                  },
                )
              : Center(child: Text('No users')),
    );
  }
}

class UserListCache implements Disposable {
  List<User>? _users;

  void setUsers(List<User> users) => _users = users;
  List<User>? getUsers() => _users;

  @override
  void dispose() {
    _users = null;
    print('UserListCache disposed');
  }
}

/// About Screen - Simple BaseScreen
class AboutScreen extends BaseScreen {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends BaseScreenState<AboutScreen> {
  @override
  void onReady() {
    print('About screen opened');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('My App', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// APP SETUP & MAIN
// ============================================================================

/// Setup all dependencies
void setupAppDependencies() {
  // Enable logging in debug mode
  DILogger.enable();

  // Core services
  locator.registerSingleton<AuthService>(AuthService());

  // API Client depends on AuthService
  locator.registerLazySingleton<ApiClient>(() {
    final auth = locator.get<AuthService>();
    return ApiClient(auth);
  });

  // Repositories
  locator.registerFactory<UserRepository>(() {
    final apiClient = locator.get<ApiClient>();
    return UserRepository(apiClient);
  });

  // Use Cases
  locator.registerFactory<LoginUseCase>(() => LoginUseCase(
        authService: locator.get<AuthService>(),
        userRepository: locator.get<UserRepository>(),
      ));

  locator.registerFactory<LogoutUseCase>(() => LogoutUseCase(
        locator.get<AuthService>(),
      ));

  locator.registerFactory<GetUsersUseCase>(() => GetUsersUseCase(
        locator.get<UserRepository>(),
      ));

  print('✅ Dependencies configured');
}

void main() {
  setupAppDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complete App Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
