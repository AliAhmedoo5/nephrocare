import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dashboard/presentation/condition_adaptive_grid.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_hub_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_intake_entry_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_output_entry_screen.dart';

void main() {
  group('Unified Application & State Seam: Consolidated Fluid Hub Card & Screen UI', () {
    late NephroTestHarness harness;
    late Patient testPatient;

    setUp(() async {
      harness = createNephroTestHarness();
      testPatient = await harness.createPatient(
        name: 'Arthur Dent',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1500,
        prescribedDryWeightKg: 70.0,
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

    testWidgets('Condition-Adaptive Grid renders consolidated Fluid Hub card with plain-language dual balance summary', (tester) async {
      final now = DateTime.now().toUtc();

      // 1. Log 550 mL intake
      await harness.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 550,
        beverageType: 'Water',
        recordedAt: now.subtract(const Duration(hours: 4)),
      );

      // 2. Log 200 mL residual native urine output
      await harness.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 200,
        outputType: 'urine',
        recordedAt: now.subtract(const Duration(hours: 3)),
      );

      // 3. Complete hemodialysis session with 2,000 mL ultrafiltration
      final session = await harness.recordPreDialysisCheckIn(
        patientId: testPatient.id,
        preWeightKg: 72.5,
        startedAt: now.subtract(const Duration(hours: 2)),
      );
      await harness.recordPostDialysisSession(
        sessionId: session.id,
        postWeightKg: 70.5,
        actualFluidRemovedMl: 2000,
        endedAt: now.subtract(const Duration(hours: 1)),
      );

      final summary = await harness.get24HourFluidBalance(testPatient.id, asOf: now);

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ConditionAdaptiveGrid(
              conditionName: testPatient.diagnosis,
              fluidSummary: summary,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Fluid Hub card is rendered
      expect(find.text('Fluid Hub'), findsOneWidget);

      // Verify plain-language dual balance metrics avoiding confusing signs
      expect(
        find.textContaining('Body Fluid Retention: +350 mL | Dialysis Removal: -2,000 mL | Net Balance: -1,650 mL'),
        findsOneWidget,
      );
    });

    testWidgets('Dashboard tapping Fluid Hub opens FluidHubScreen presenting retention, dialysis removal, and net balance', (tester) async {
      final now = DateTime.now().toUtc();

      // Seed dual balance data: 550 mL intake, 200 mL urine, 2,000 mL dialysis removal
      await harness.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 550,
        beverageType: 'Water',
        recordedAt: now.subtract(const Duration(hours: 4)),
      );
      await harness.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 200,
        outputType: 'urine',
        recordedAt: now.subtract(const Duration(hours: 3)),
      );
      final session = await harness.recordPreDialysisCheckIn(
        patientId: testPatient.id,
        preWeightKg: 72.5,
        startedAt: now.subtract(const Duration(hours: 2)),
      );
      await harness.recordPostDialysisSession(
        sessionId: session.id,
        postWeightKg: 70.5,
        actualFluidRemovedMl: 2000,
        endedAt: now.subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(createTestableWidget(DashboardScreen(patient: testPatient)));
      await tester.pumpAndSettle();

      // Find and tap Fluid Hub card
      final fluidHubCard = find.text('Fluid Hub');
      expect(fluidHubCard, findsOneWidget);
      await tester.ensureVisible(fluidHubCard);
      await tester.tap(fluidHubCard);
      await tester.pumpAndSettle();

      // Verify navigated to FluidHubScreen
      expect(find.byType(FluidHubScreen), findsOneWidget);

      // Verify plain-language metrics on FluidHubScreen
      expect(find.byKey(const Key('fluid_hub_retention_card')), findsOneWidget);
      expect(find.textContaining('+350 mL'), findsWidgets);
      expect(find.textContaining('Body Fluid Retention'), findsWidgets);

      expect(find.byKey(const Key('fluid_hub_dialysis_removal_card')), findsOneWidget);
      expect(find.textContaining('-2,000 mL'), findsWidgets);
      expect(find.textContaining('Dialysis Removal'), findsWidgets);

      expect(find.byKey(const Key('fluid_hub_net_balance_card')), findsOneWidget);
      expect(find.textContaining('-1,650 mL'), findsWidgets);
      expect(find.textContaining('Net 24-Hour Balance'), findsWidgets);

      // Verify quick action buttons exist and have min 48dp height
      final intakeButton = find.byKey(const Key('fluid_hub_log_intake_button'));
      final outputButton = find.byKey(const Key('fluid_hub_log_output_button'));
      expect(intakeButton, findsOneWidget);
      expect(outputButton, findsOneWidget);

      final intakeSize = tester.getSize(intakeButton);
      expect(intakeSize.height, greaterThanOrEqualTo(48.0));
      final outputSize = tester.getSize(outputButton);
      expect(outputSize.height, greaterThanOrEqualTo(48.0));

      // Test tapping Intake button navigates to FluidIntakeEntryScreen
      await tester.ensureVisible(intakeButton);
      await tester.tap(intakeButton);
      await tester.pumpAndSettle();
      expect(find.byType(FluidIntakeEntryScreen), findsOneWidget);

      // Navigate back and tap Output button
      Navigator.of(tester.element(find.byType(FluidIntakeEntryScreen))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(outputButton);
      await tester.tap(outputButton);
      await tester.pumpAndSettle();
      expect(find.byType(FluidOutputEntryScreen), findsOneWidget);
    });
  });
}
