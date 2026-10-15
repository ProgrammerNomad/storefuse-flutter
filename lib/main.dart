import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromDartDefines();
  env.validate();
  if (kDebugMode) {
    debugPrint('StoreFuse API: ${env.apiBaseUrl} (flavor: ${env.flavor})');
  }
  runApp(const ProviderScope(child: StoreFuseApp()));
}
