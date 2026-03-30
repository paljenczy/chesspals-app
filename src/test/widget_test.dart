import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chesspals/src/app.dart';

void main() {
  testWidgets('App smoke test — 3 tabs visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ChessPalsApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Play Bot'), findsOneWidget);
    expect(find.text('Puzzles'), findsOneWidget);
    expect(find.text('Play Human'), findsOneWidget);
  });
}
