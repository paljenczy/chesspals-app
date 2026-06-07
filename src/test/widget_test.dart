import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chesspals/src/app.dart';

void main() {
  testWidgets('App smoke test — app renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ChessPalsApp()),
    );
    // Allow async initialization (router, locale, providers)
    await tester.pump(const Duration(seconds: 1));

    // Verify the MaterialApp is in the tree
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
