import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';

void main() {
  testWidgets('NephroCareApp launches cleanly and displays offline engine status', (WidgetTester tester) async {
    final harness = createNephroTestHarness();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: const NephroCareApp(),
      ),
    );

    // Initial frame
    await tester.pump();

    expect(find.text('NephroCare'), findsOneWidget);
    expect(find.text('Offline Clinical Engine Ready'), findsOneWidget);
    expect(find.text('Embedded Drift SQLite & Riverpod initialized.'), findsOneWidget);

    await harness.dispose();
  });
}
