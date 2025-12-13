/// UI Base Classes
///
/// Base screen classes with automatic scope and disposal management.
///
/// ## Quick Start
/// ```dart
/// // ScopedScreen - with scoped services
/// class ProfileScreen extends ScopedScreen {
///   @override
///   State<ProfileScreen> createState() => _ProfileScreenState();
/// }
///
/// class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
///   @override
///   void registerServices() {
///     registerSingleton<ProfileCache>(ProfileCache());
///   }
///
///   @override
///   void onReady() {
///     // Called after first frame
///   }
///
///   @override
///   void onDispose() {
///     // Clean up
///   }
///
///   @override
///   Widget build(BuildContext context) => Container();
/// }
///
/// // BaseScreen - without scoping
/// class SimpleScreen extends BaseScreen {
///   @override
///   State<SimpleScreen> createState() => _SimpleScreenState();
/// }
///
/// class _SimpleScreenState extends BaseScreenState<SimpleScreen> {
///   @override
///   void onDispose() {
///     // Clean up
///   }
///
///   @override
///   Widget build(BuildContext context) => Container();
/// }
/// ```
library;

export 'scoped_screen.dart';
export 'base_screen.dart';
