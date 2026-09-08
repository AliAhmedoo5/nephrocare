import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';

void main() {
  testWidgets('NephroCareApp launches cleanly into Patient Profile Setup when database is uninitialized',
      (WidgetTester tester) async {
    final harness = createNephroTestHarness();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: const NephroCareApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Patient Profile Setup'), findsOneWidget);
    expect(find.text('Offline Clinical Profile'), findsOneWidget);

    await harness.dispose();
  });

  testWidgets('NephroCareApp launches cleanly into Condition-Adaptive Grid when patient profile exists',
      (WidgetTester tester) async {
    final harness = createNephroTestHarness();

    await harness.createPatient(
      name: 'Sarah Jenkins',
      diagnosis: 'hemodialysis',
      prescribedDryWeightKg: 62.0,
      dailyFluidAllowanceMl: 1000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: const NephroCareApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NephroCare'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Hemodialysis'), findsOneWidget);
    expect(find.text('Check-in'), findsOneWidget);

    await harness.dispose();
  });
}
