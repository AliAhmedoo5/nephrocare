import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/catheter/data/catheter_repository.dart';
import 'package:nephrocare/src/features/catheter/domain/catheter_lifespan_rules.dart';
import 'package:nephrocare/src/features/catheter/presentation/catheter_lifespan_screen.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  group('Unified Application & State Seam: Catheter Lifespan UI & CAUTI Risk Monitor', () {
    late NephroTestHarness harness;
    late Patient patient;

    setUp(() async {
      harness = createNephroTestHarness();
      patient = await harness.createPatient(
        name: 'Harold Finch',
        diagnosis: 'urologicalCatheter',
        dailyFluidAllowanceMl: 2000,
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

    testWidgets('Displays empty state when no active catheter exists and allows recording initial insertion', (tester) async {
      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.text('No Active Urine Foley Catheter'), findsOneWidget);
      expect(find.byKey(const Key('record_catheter_insertion_button')), findsOneWidget);

      // Tap record insertion button
      await tester.tap(find.byKey(const Key('record_catheter_insertion_button')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.widgetWithText(AlertDialog, 'Record Catheter Insertion'), findsOneWidget);
      final confirmBtn = find.byKey(const Key('confirm_catheter_event_button'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verifies active catheter is now rendered on Day 1 (Green)
      expect(find.textContaining('Day 1 of 14'), findsOneWidget);
      expect(find.textContaining('Lifespan Optimal'), findsOneWidget);
    });

    testWidgets('Renders Green state for catheter on days 1 to 10', (tester) async {
      final now = DateTime.now().toUtc();
      final insertDate = now.subtract(const Duration(days: 4)); // Day 5

      await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: insertDate,
        replacementDueDate: insertDate.add(const Duration(days: 14)),
        status: 'active',
      );

      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Day 5 of 14'), findsOneWidget);
      expect(find.textContaining('Lifespan Optimal'), findsOneWidget);
      expect(find.byKey(const Key('cauti_risk_window_alert')), findsNothing);
    });

    testWidgets('Renders Amber state for catheter on days 11 to 14', (tester) async {
      final now = DateTime.now().toUtc();
      final insertDate = now.subtract(const Duration(days: 11)); // Day 12

      await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: insertDate,
        replacementDueDate: insertDate.add(const Duration(days: 14)),
        status: 'active',
      );

      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Day 12 of 14'), findsOneWidget);
      expect(find.textContaining('Replacement Approaching'), findsOneWidget);
      expect(find.byKey(const Key('cauti_risk_window_alert')), findsNothing);
    });

    testWidgets('Renders Red CAUTI Risk Window alert for catheter on days 15+', (tester) async {
      final now = DateTime.now().toUtc();
      final insertDate = now.subtract(const Duration(days: 15)); // Day 16

      await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: insertDate,
        replacementDueDate: insertDate.add(const Duration(days: 14)),
        status: 'active',
      );

      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Day 16 of 14'), findsOneWidget);
      expect(find.textContaining('CAUTI Risk Window Active'), findsWidgets);
      expect(find.byKey(const Key('cauti_risk_window_alert')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('cauti_risk_window_alert')),
          matching: find.textContaining('High risk of Catheter-Associated Urinary Tract Infection'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Logging catheter replacement retires old catheter and restarts 14-day cycle to Day 1', (tester) async {
      final now = DateTime.now().toUtc();
      final oldDate = now.subtract(const Duration(days: 16)); // Day 17 (CAUTI risk)

      await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: oldDate,
        replacementDueDate: oldDate.add(const Duration(days: 14)),
        status: 'active',
      );

      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify Red alert present
      expect(find.byKey(const Key('cauti_risk_window_alert')), findsOneWidget);

      // Tap Log Catheter Replacement button
      final replaceButton = find.byKey(const Key('log_catheter_replacement_button'));
      expect(replaceButton, findsOneWidget);
      await tester.ensureVisible(replaceButton);
      await tester.tap(replaceButton);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.widgetWithText(AlertDialog, 'Log Catheter Replacement'), findsOneWidget);
      final confirmBtn = find.byKey(const Key('confirm_catheter_event_button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify cycle reset to Day 1 Green
      expect(find.textContaining('Day 1 of 14'), findsOneWidget);
      expect(find.textContaining('Lifespan Optimal'), findsOneWidget);
      expect(find.byKey(const Key('cauti_risk_window_alert')), findsNothing);

      // Verify history contains 2 entries
      final history = await harness.container.read(catheterRepositoryProvider).getCatheterHistory(patient.id);
      expect(history.length, equals(2));
      expect(history.where((e) => e.status == 'active').length, equals(1));
      expect(history.where((e) => e.status == 'replaced').length, equals(1));
    });

    testWidgets('Allows selecting 30-day silicone material and 6-hour bag emptying interval', (tester) async {
      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_catheter_insertion_button')));
      await tester.pumpAndSettle();

      // Material dropdown
      final materialDropdown = find.byKey(const Key('catheter_material_dropdown'));
      expect(materialDropdown, findsOneWidget);
      await tester.tap(materialDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('30-Day Silicone').last);
      await tester.pumpAndSettle();

      // Interval dropdown
      final intervalDropdown = find.byKey(const Key('bag_emptying_interval_dropdown'));
      expect(intervalDropdown, findsOneWidget);
      await tester.tap(intervalDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Every 6 Hours').last);
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.byKey(const Key('confirm_catheter_event_button')));
      await tester.pumpAndSettle();

      // Verifies Day 1 of 30 and 30-Day Silicone rendered
      expect(find.textContaining('Day 1 of 30'), findsOneWidget);
      expect(find.textContaining('30-Day Silicone'), findsWidgets);
      expect(find.byKey(const Key('bag_emptying_status_card')), findsOneWidget);
      expect(find.textContaining('Every 6 hours'), findsOneWidget);
    });

    testWidgets('1-tap "Bag Emptied" action captures volume and Hematuria Grade in a single step', (tester) async {
      // Set up active catheter with 4-hour interval
      await harness.container.read(catheterRepositoryProvider).recordCatheterInsertion(
        patientId: patient.id,
        insertionDate: DateTime.now().toUtc(),
        material: CatheterMaterial.latex14Day,
        bagEmptyingIntervalHours: 4,
      );

      await tester.pumpWidget(createTestableWidget(CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Locate 1-tap Bag Emptied button
      final bagEmptiedBtn = find.byKey(const Key('one_tap_bag_emptied_button'));
      expect(bagEmptiedBtn, findsOneWidget);
      await tester.ensureVisible(bagEmptiedBtn);
      await tester.tap(bagEmptiedBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byKey(const Key('bag_emptied_dialog')), findsOneWidget);

      // Select 400 mL preset chip
      final chip400 = find.byKey(const Key('volume_chip_400'));
      expect(chip400, findsOneWidget);
      await tester.tap(chip400);
      await tester.pumpAndSettle();

      // Select Hematuria Grade 2 chip
      final grade2Chip = find.byKey(const Key('hematuria_chip_2'));
      expect(grade2Chip, findsOneWidget);
      await tester.tap(grade2Chip);
      await tester.pumpAndSettle();

      // Tap Confirm Bag Emptied
      final confirmBtn = find.byKey(const Key('confirm_bag_emptied_button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar or status updated
      expect(find.textContaining('Bag emptied recorded'), findsOneWidget);

      // Verify in database: FluidOutputLog created
      final outputLogs = await harness.container.read(databaseProvider).select(harness.database.fluidOutputLogs).get();
      expect(outputLogs.length, equals(1));
      expect(outputLogs.first.volumeMl, equals(400));
      expect(outputLogs.first.hematuriaGrade, equals(2));
      expect(outputLogs.first.outputType, equals('urine'));
    });

    testWidgets('Foley catheter tracking is accessible from Dashboard across all condition profiles', (tester) async {
      final conditions = ['hemodialysis', 'peritonealDialysis', 'nonDialysisCkd'];

      for (final condition in conditions) {
        final condPatient = await harness.createPatient(
          name: 'Patient $condition',
          diagnosis: condition,
          dailyFluidAllowanceMl: 1500,
        );

        await tester.pumpWidget(createTestableWidget(DashboardScreen(patient: condPatient)));
        await tester.pumpAndSettle();

        // Verify open catheter button in AppBar
        final catheterBtn = find.byKey(const Key('open_catheter_button'));
        expect(catheterBtn, findsOneWidget);

        await tester.tap(catheterBtn);
        await tester.pumpAndSettle();

        // Verify navigated to CatheterLifespanScreen
        expect(find.byType(CatheterLifespanScreen), findsOneWidget);
        expect(find.text('No Active Urine Foley Catheter'), findsOneWidget);

        // Pop back to dashboard
        Navigator.of(tester.element(find.byType(CatheterLifespanScreen))).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Tapping Foley Catheter tile on Dashboard opens CatheterLifespanScreen for Non-Dialysis CKD patient', (tester) async {
      final ckdPatient = await harness.createPatient(
        name: 'CKD Foley Patient',
        diagnosis: 'nonDialysisCkd',
        dailyFluidAllowanceMl: 1500,
      );

      // Insert an active catheter
      await harness.container.read(catheterRepositoryProvider).recordCatheterInsertion(
        patientId: ckdPatient.id,
        insertionDate: DateTime.now().toUtc(),
        material: CatheterMaterial.silicone30Day,
      );

      await tester.pumpWidget(createTestableWidget(DashboardScreen(patient: ckdPatient)));
      await tester.pumpAndSettle();

      // Verify catheter metric tile is present
      final metricTile = find.byKey(const Key('dashboard_catheter_metric_tile'));
      expect(metricTile, findsOneWidget);
      expect(find.textContaining('Day 1 of 30'), findsOneWidget);

      // Tap the metric tile
      await tester.tap(metricTile);
      await tester.pumpAndSettle();

      // Verify navigated to CatheterLifespanScreen showing active 30-day catheter
      expect(find.byType(CatheterLifespanScreen), findsOneWidget);
      expect(find.textContaining('30-Day Silicone'), findsWidgets);
    });
  });
}
