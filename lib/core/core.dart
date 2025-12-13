/// Core Module
///
/// Provides DI container, service locator, and base screen classes.
///
/// ## Quick Import
/// ```dart
/// import 'package:personal_codex/core/core.dart';
/// ```
///
/// ## What's Included
/// - DI Container & Service Locator
/// - Scoped Service Management
/// - Base Screen Classes
/// - Disposable Interface
/// - Debug Logger
library;

// DI System
export 'di/di_container.dart';
export 'di/service_locator.dart';
export 'di/disposable.dart';
export 'di/di_logger.dart';
export 'di/app_composition.dart';

// UI Base Classes
export 'ui/scoped_screen.dart';
export 'ui/base_screen.dart';
