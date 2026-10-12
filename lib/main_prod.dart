import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Production entry - requires `--dart-define=BRIDGE_BASE_URL=https://your-shop.com`
/// and `--dart-define=APP_FLAVOR=prod`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StoreFuseApp()));
}
