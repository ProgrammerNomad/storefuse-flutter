import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnv.fromDartDefines().validate();
  runApp(const ProviderScope(child: StoreFuseApp()));
}
