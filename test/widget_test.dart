import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storefuse_app/app.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StoreFuseApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
