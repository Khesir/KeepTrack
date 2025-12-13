import 'package:flutter/material.dart';
import '../scoped_screen.dart';
import '../base_screen.dart';
import '../../di/service_locator.dart';

// Example services
class ProfileCache {
  final Map<String, dynamic> _cache = {};

  void set(String key, dynamic value) {
    _cache[key] = value;
    print('Cache set: $key');
  }

  dynamic get(String key) => _cache[key];

  void clear() {
    _cache.clear();
    print('Cache cleared');
  }
}

class ProfileApiClient {
  Future<Map<String, dynamic>> fetchProfile() async {
    await Future.delayed(Duration(seconds: 1));
    return {'name': 'John Doe', 'email': 'john@example.com'};
  }
}

// ============================================================================
// Example 1: ScopedScreen with scoped services
// ============================================================================

class ProfileScreen extends ScopedScreen {
  const ProfileScreen({super.key});

  @override
  String? get scopeName => 'ProfileScreen';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  @override
  void registerServices() {
    // Register screen-specific services
    registerSingleton<ProfileCache>(ProfileCache());
    registerSingleton<ProfileApiClient>(ProfileApiClient());
  }

  @override
  void onReady() {
    // Called after first frame
    _loadProfile();
  }

  @override
  void onDispose() {
    // Clean up resources
    print('ProfileScreen disposing...');
    final cache = getService<ProfileCache>();
    cache.clear();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final cache = getService<ProfileCache>();
    final apiClient = getService<ProfileApiClient>();

    // Check cache first
    var data = cache.get('profile');

    if (data == null) {
      // Fetch from API
      data = await apiClient.fetchProfile();
      cache.set('profile', data);
    }

    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _profileData != null
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${_profileData!['name']}',
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Email: ${_profileData!['email']}',
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : Center(child: Text('No data')),
    );
  }
}

// ============================================================================
// Example 2: BaseScreen without scoping
// ============================================================================

class SimpleCounterScreen extends BaseScreen {
  const SimpleCounterScreen({super.key});

  @override
  State<SimpleCounterScreen> createState() => _SimpleCounterScreenState();
}

class _SimpleCounterScreenState extends BaseScreenState<SimpleCounterScreen> {
  int _counter = 0;

  @override
  void onReady() {
    print('SimpleCounterScreen ready');
  }

  @override
  void onDispose() {
    print('SimpleCounterScreen disposing, final count: $_counter');
  }

  void _increment() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: $_counter', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _increment,
              child: Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Example 3: Advanced - Multiple scoped services with dependencies
// ============================================================================

class SettingsCache {
  final Map<String, dynamic> _settings = {'theme': 'dark', 'notifications': true};

  dynamic getSetting(String key) => _settings[key];

  void setSetting(String key, dynamic value) {
    _settings[key] = value;
    print('Setting updated: $key = $value');
  }
}

class SettingsRepository {
  final SettingsCache cache;

  SettingsRepository(this.cache);

  Future<void> saveSetting(String key, dynamic value) async {
    cache.setSetting(key, value);
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));
    print('Setting saved to server: $key');
  }

  dynamic getSetting(String key) => cache.getSetting(key);
}

class SettingsScreen extends ScopedScreen {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ScopedScreenState<SettingsScreen> {
  late SettingsRepository _repository;
  bool _notificationsEnabled = true;

  @override
  void registerServices() {
    // Register services with dependencies
    registerSingleton<SettingsCache>(SettingsCache());

    // Repository depends on cache
    final cache = getService<SettingsCache>();
    registerSingleton<SettingsRepository>(SettingsRepository(cache));
  }

  @override
  void onReady() {
    _repository = getService<SettingsRepository>();
    final notifications = _repository.getSetting('notifications') as bool?;
    setState(() {
      _notificationsEnabled = notifications ?? true;
    });
  }

  @override
  void onDispose() {
    print('SettingsScreen disposing...');
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _repository.saveSetting('notifications', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 4: Screen with global service access
// ============================================================================

// Assume AuthService is registered globally
class AuthService {
  String? token;
  bool get isAuthenticated => token != null;
}

class DashboardScreen extends ScopedScreen {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ScopedScreenState<DashboardScreen> {
  late AuthService _authService;

  @override
  void registerServices() {
    // Can register scoped services if needed
    // But also can access global services
  }

  @override
  void onReady() {
    // Access global service
    _authService = getService<AuthService>();

    if (!_authService.isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Center(child: Text('Welcome!')),
    );
  }
}

// ============================================================================
// Example app
// ============================================================================

void main() {
  // Setup global services
  locator.registerSingleton<AuthService>(AuthService()..token = 'test-token');

  runApp(MaterialApp(
    home: ProfileScreen(),
    routes: {
      '/login': (context) => SimpleCounterScreen(),
      '/settings': (context) => SettingsScreen(),
      '/dashboard': (context) => DashboardScreen(),
    },
  ));
}
