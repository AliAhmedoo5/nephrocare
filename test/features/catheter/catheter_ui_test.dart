import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/catheter/data/catheter_repository.dart';
import 'package:nephrocare/src/features/catheter/presentation/catheter_lifespan_screen.dart';

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
  });
}
