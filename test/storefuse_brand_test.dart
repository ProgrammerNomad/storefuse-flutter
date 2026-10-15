import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storefuse_app/core/widgets/storefuse_brand.dart';

void main() {
  testWidgets('StoreFuse lockup renders the shared mark and store label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StoreFuseBrandLockup(name: 'Example Store')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Example Store'), findsOneWidget);
    expect(find.bySemanticsLabel('StoreFuse'), findsOneWidget);
  });
}
