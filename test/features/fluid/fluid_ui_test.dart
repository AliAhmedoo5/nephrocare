import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_intake_entry_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_output_entry_screen.dart';

void main() {
  group('Unified Application & State Seam: Fluid UI Logging & Visual Progression', () {
    late NephroTestHarness harness;
    late Patient patient;

    setUp(() async {
      harness = createNephroTestHarness();
      patient = await harness.createPatient(
        name: 'Edward Jenner',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1500,
        prescribedDryWeightKg: 72.0,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    Widget createTestableWidget(Widget child) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Fluid intake screen supports rapid presets, custom volume entry, visual allowance progression, and phosphate binder reminder', (tester) async {
      await tester.pumpWidget(createTestableWidget(FluidIntakeEntryScreen(patient: patient)));
      await tester.pumpAndSettle();

      // 1. Verify Prescribed Fluid Allowance visual progression header
      expect(find.text('Daily Fluid Allowance Tracker'), findsOneWidget);
      expect(find.textContaining('1500 mL'), findsWidgets);
      expect(find.textContaining('Within Limit'), findsOneWidget);

      // 2. Verify Rapid Presets exist
      expect(find.byKey(const Key('preset_100_button')), findsOneWidget);
      expect(find.byKey(const Key('preset_150_button')), findsOneWidget);
      expect(find.byKey(const Key('preset_250_button')), findsOneWidget);

      // Tap Preset 250ml and verify volume input updates
      await tester.tap(find.byKey(const Key('preset_250_button')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '250'), findsOneWidget);

      // 3. Custom volume entry: enter 350 mL
      final volumeInput = find.byKey(const Key('volume_input'));
      await tester.enterText(volumeInput, '350');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '350'), findsOneWidget);

      // 4. Verify Contextual Phosphate Binder reminder prompt per CONTEXT.md
      expect(
        find.textContaining('Phosphate Binders must be ingested strictly during or immediately following meals and fluids'),
        findsOneWidget,
      );

      // Toggle Phosphate Binder checkbox
      final binderToggle = find.byKey(const Key('phosphate_binder_toggle'));
      expect(binderToggle, findsOneWidget);
      await tester.ensureVisible(binderToggle);
      await tester.tap(binderToggle);
      await tester.pumpAndSettle();

      // 5. Submit intake log
      final saveButton = find.byKey(const Key('save_fluid_intake_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation
      expect(find.textContaining('Fluid intake logged: 350 mL'), findsOneWidget);

      // Verify database record via harness
      final logs = await harness.getFluidIntakeLogs(patient.id);
      expect(logs.length, equals(1));
      expect(logs.first.volumeMl, equals(350));
      expect(logs.first.phosphateBinderTaken, isTrue);

      // Verify visual progression updated dynamically
      final balance = await harness.get24HourFluidBalance(patient.id);
      expect(balance.totalIntakeMl, equals(350));
      expect(balance.remainingAllowanceMl, equals(1150));
      expect(balance.intakePercentageOfAllowance, equals(23.3));
    });

    testWidgets('Fluid output screen logs evacuation volume, hematuria grade, and updates 24h balance dynamically', (tester) async {
      // First seed an intake of 800 mL
      await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 800,
        beverageType: 'Water',
        recordedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(createTestableWidget(FluidOutputEntryScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify 24h Fluid Balance preview
      expect(find.text('24-Hour Fluid Balance'), findsOneWidget);
      expect(find.textContaining('Intake: 800 mL'), findsOneWidget);

      // Select preset 200 mL
      expect(find.byKey(const Key('preset_output_200_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('preset_output_200_button')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '200'), findsOneWidget);

      // Select Hematuria Grade 2
      final hematuriaGrade2 = find.byKey(const Key('hematuria_grade_2'));
      await tester.ensureVisible(hematuriaGrade2);
      await tester.tap(hematuriaGrade2);
      await tester.pumpAndSettle();

      // Save Output Log
      final saveOutputButton = find.byKey(const Key('save_fluid_output_button'));
      await tester.ensureVisible(saveOutputButton);
      await tester.tap(saveOutputButton);
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation
      expect(find.textContaining('Fluid output logged: 200 mL (urine)'), findsOneWidget);

      // Verify database persistence
      final outputs = await harness.getFluidOutputLogs(patient.id);
      expect(outputs.length, equals(1));
      expect(outputs.first.volumeMl, equals(200));
      expect(outputs.first.outputType, equals('urine'));
      expect(outputs.first.hematuriaGrade, equals(2));

      // Verify dynamic 24h Fluid Balance rollup: 800 - 200 = +600 mL
      final balance = await harness.get24HourFluidBalance(patient.id);
      expect(balance.totalIntakeMl, equals(800));
      expect(balance.totalOutputMl, equals(200));
      expect(balance.netBalanceMl, equals(600));
    });
  });
}
