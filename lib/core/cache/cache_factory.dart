import 'package:flutter/foundation.dart' show kIsWeb;
import 'hive_local_cache.dart';
import 'local_cache.dart';
import 'memory_local_cache.dart';

LocalCache createLocalCache() => kIsWeb ? MemoryLocalCache() : HiveLocalCache();
