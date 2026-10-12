import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Dev entry: default base URL `http://10.0.2.2` (Android emulator → host localhost).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StoreFuseApp()));
}
