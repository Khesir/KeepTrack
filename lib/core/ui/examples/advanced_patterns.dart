import 'dart:async';
import 'package:flutter/material.dart';
import '../scoped_screen.dart';
import '../../di/service_locator.dart';
import '../../di/disposable.dart';

// ============================================================================
// Pattern 1: Screen with Stream Controllers
// ============================================================================

class ChatService implements Disposable {
  final _messageController = StreamController<String>.broadcast();

  Stream<String> get messages => _messageController.stream;

  void sendMessage(String message) {
    _messageController.add(message);
  }

  @override
  void dispose() {
    _messageController.close();
    print('ChatService disposed - stream closed');
  }
}

class ChatScreen extends ScopedScreen {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ScopedScreenState<ChatScreen> {
  final List<String> _messages = [];
  StreamSubscription<String>? _subscription;

  @override
  void registerServices() {
    registerSingleton<ChatService>(ChatService());
  }

  @override
  void onReady() {
    final chatService = getService<ChatService>();

    // Subscribe to messages
    _subscription = chatService.messages.listen((message) {
      setState(() => _messages.add(message));
    });

    // Send initial message
    chatService.sendMessage('Welcome!');
  }

  @override
  void onDispose() {
    // Cancel subscription before service disposal
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_messages[index]),
        ),
      ),
    );
  }
}

// ============================================================================
// Pattern 2: Screen with Timer/Periodic Tasks
// ============================================================================

class PollingService {
  final void Function(int) onPoll;

  PollingService(this.onPoll);

  Timer? _timer;
  int _count = 0;

  void start() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _count++;
      onPoll(_count);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class DashboardScreen extends ScopedScreen {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ScopedScreenState<DashboardScreen> {
  int _pollCount = 0;
  late PollingService _pollingService;

  @override
  void registerServices() {
    _pollingService = PollingService((count) {
      if (mounted) {
        setState(() => _pollCount = count);
      }
    });
    registerSingleton<PollingService>(_pollingService);
  }

  @override
  void onReady() {
    _pollingService.start();
  }

  @override
  void onDispose() {
    _pollingService.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Center(child: Text('Polls: $_pollCount')),
    );
  }
}

// ============================================================================
// Pattern 3: Screen with Form Controllers
// ============================================================================

class FormManager implements Disposable {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool validate() {
    return emailController.text.isNotEmpty &&
        passwordController.text.length >= 6;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    print('Form controllers disposed');
  }
}

class LoginScreen extends ScopedScreen {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ScopedScreenState<LoginScreen> {
  late FormManager _formManager;

  @override
  void registerServices() {
    registerSingleton<FormManager>(FormManager());
  }

  @override
  void onReady() {
    _formManager = getService<FormManager>();
  }

  void _handleLogin() {
    if (_formManager.validate()) {
      print('Login with: ${_formManager.emailController.text}');
    } else {
      print('Invalid form');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _formManager.emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _formManager.passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Pattern 4: Screen with Animation Controllers
// ============================================================================

class AnimationManager implements Disposable {
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  void init(TickerProvider vsync) {
    fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: vsync,
    );
    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeIn,
    );
  }

  void fadeIn() {
    fadeController.forward();
  }

  void fadeOut() {
    fadeController.reverse();
  }

  @override
  void dispose() {
    fadeController.dispose();
    print('Animation controller disposed');
  }
}

class SplashScreen extends ScopedScreen {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ScopedScreenState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationManager _animationManager;

  @override
  void registerServices() {
    final animManager = AnimationManager();
    animManager.init(this); // Pass TickerProvider
    registerSingleton<AnimationManager>(animManager);
  }

  @override
  void onReady() {
    _animationManager = getService<AnimationManager>();
    _animationManager.fadeIn();

    // Navigate after animation
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _animationManager.fadeAnimation,
        child: Center(child: Text('Splash', style: TextStyle(fontSize: 32))),
      ),
    );
  }
}

// ============================================================================
// Pattern 5: Screen with Focus Nodes
// ============================================================================

class FocusManager implements Disposable {
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  void focusEmail() {
    emailFocusNode.requestFocus();
  }

  void focusPassword() {
    passwordFocusNode.requestFocus();
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    print('Focus nodes disposed');
  }
}

// ============================================================================
// Pattern 6: Screen with Scroll Controllers
// ============================================================================

class ScrollManager implements Disposable {
  final scrollController = ScrollController();
  bool _showFab = false;

  void init(VoidCallback onUpdate) {
    scrollController.addListener(() {
      final shouldShow = scrollController.offset > 200;
      if (shouldShow != _showFab) {
        _showFab = shouldShow;
        onUpdate();
      }
    });
  }

  bool get showFab => _showFab;

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    print('Scroll controller disposed');
  }
}

class ArticleListScreen extends ScopedScreen {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends ScopedScreenState<ArticleListScreen> {
  late ScrollManager _scrollManager;

  @override
  void registerServices() {
    final scrollMgr = ScrollManager();
    scrollMgr.init(() => setState(() {}));
    registerSingleton<ScrollManager>(scrollMgr);
  }

  @override
  void onReady() {
    _scrollManager = getService<ScrollManager>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Articles')),
      body: ListView.builder(
        controller: _scrollManager.scrollController,
        itemCount: 50,
        itemBuilder: (context, index) => ListTile(
          title: Text('Article $index'),
        ),
      ),
      floatingActionButton: _scrollManager.showFab
          ? FloatingActionButton(
              onPressed: _scrollManager.scrollToTop,
              child: Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}

// ============================================================================
// Pattern 7: Screen with Multiple Dependencies
// ============================================================================

class UserCache {
  final Map<String, dynamic> _cache = {};

  void cache(String key, dynamic value) => _cache[key] = value;
  dynamic get(String key) => _cache[key];
  void clear() => _cache.clear();
}

class UserApi {
  Future<Map<String, dynamic>> fetchUser(String id) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'id': id, 'name': 'User $id'};
  }
}

class UserRepository {
  final UserCache cache;
  final UserApi api;

  UserRepository({required this.cache, required this.api});

  Future<Map<String, dynamic>> getUser(String id) async {
    var user = cache.get(id);
    if (user == null) {
      user = await api.fetchUser(id);
      cache.cache(id, user);
    }
    return user;
  }
}

class UserProfileScreen extends ScopedScreen {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ScopedScreenState<UserProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void registerServices() {
    // Register in dependency order
    registerSingleton<UserCache>(UserCache());
    registerSingleton<UserApi>(UserApi());

    // Repository depends on cache and api
    final cache = getService<UserCache>();
    final api = getService<UserApi>();
    registerSingleton<UserRepository>(
      UserRepository(cache: cache, api: api),
    );
  }

  @override
  void onReady() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final repo = getService<UserRepository>();
    final user = await repo.getUser(widget.userId);
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: _user != null
          ? Center(child: Text(_user!['name']))
          : Center(child: CircularProgressIndicator()),
    );
  }
}

// ============================================================================
// Pattern 8: Screen State Restoration
// ============================================================================

class StateManager {
  Map<String, dynamic> state = {};

  void saveState(String key, dynamic value) {
    state[key] = value;
  }

  T? getState<T>(String key) {
    return state[key] as T?;
  }

  void clearState() {
    state.clear();
  }
}

class StatefulFormScreen extends ScopedScreen {
  const StatefulFormScreen({super.key});

  @override
  State<StatefulFormScreen> createState() => _StatefulFormScreenState();
}

class _StatefulFormScreenState extends ScopedScreenState<StatefulFormScreen> {
  late StateManager _stateManager;
  late TextEditingController _controller;

  @override
  void registerServices() {
    registerSingleton<StateManager>(StateManager());
  }

  @override
  void onReady() {
    _stateManager = getService<StateManager>();
    _controller = TextEditingController();

    // Restore state if exists
    final savedText = _stateManager.getState<String>('formText');
    if (savedText != null) {
      _controller.text = savedText;
    }

    // Auto-save on change
    _controller.addListener(() {
      _stateManager.saveState('formText', _controller.text);
    });
  }

  @override
  void onDispose() {
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(labelText: 'Type something...'),
        ),
      ),
    );
  }
}
