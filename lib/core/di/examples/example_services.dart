import '../disposable.dart';

/// Example service that doesn't need disposal
class AuthService {
  String? _token;

  Future<void> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 100));
    _token = 'auth-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  void logout() {
    _token = null;
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
}

/// Example service that implements Disposable
class DatabaseService implements Disposable {
  bool _isConnected = false;

  void connect() {
    print('Database connected');
    _isConnected = true;
  }

  void query(String sql) {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    print('Executing: $sql');
  }

  @override
  void dispose() {
    print('Database connection closed');
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}

/// Example service with async disposal
class FileStorageService implements Disposable {
  final List<String> _openFiles = [];

  void openFile(String path) {
    _openFiles.add(path);
    print('Opened file: $path');
  }

  @override
  void dispose() {
    for (final file in _openFiles) {
      print('Closed file: $file');
    }
    _openFiles.clear();
  }
}

/// Example repository that depends on other services
class UserRepository {
  final AuthService authService;
  final DatabaseService databaseService;

  UserRepository({
    required this.authService,
    required this.databaseService,
  });

  Future<User> getCurrentUser() async {
    if (!authService.isAuthenticated) {
      throw Exception('Not authenticated');
    }

    databaseService.query('SELECT * FROM users WHERE token = ${authService.token}');
    return User(id: '1', name: 'John Doe');
  }
}

/// Example use case
class LoginUseCase {
  final UserRepository repository;

  LoginUseCase({required this.repository});

  Future<User> execute(String email, String password) async {
    await repository.authService.login(email, password);
    return repository.getCurrentUser();
  }
}

/// Simple user model
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}
