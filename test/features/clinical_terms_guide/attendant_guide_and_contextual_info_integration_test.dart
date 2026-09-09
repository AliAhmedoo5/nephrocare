import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/presentation/blood_pressure_entry_screen.dart';
import 'package:nephrocare/src/features/catheter/presentation/catheter_lifespan_screen.dart';
import 'package:nephrocare/src/features/clinical_terms_guide/presentation/caregiver_terms_guide_screen.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_check_in_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_hub_screen.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';
import 'package:nephrocare/src/features/reports/presentation/modular_clinical_report_screen.dart';

void main() {
  group('Unified UI & Harness Seam: Attendant Guide & Contextual Info System (Issue #21)', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Widget createTestApp({required Widget home}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: MaterialApp(
          home: home,
        ),
      );
    }

    testWidgets('DashboardScreen AppBar contains accessible 48dp button that navigates to CaregiverTermsGuideScreen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final patient = await harness.createPatient(
        name: 'Sarah Jenkins',
        diagnosis: ClinicalCondition.hemodialysis.name,
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      final guideBtn = find.byKey(const Key('open_terms_guide_button'));
      expect(guideBtn, findsOneWidget);

      final btnSize = tester.getSize(guideBtn);
      expect(btnSize.width, greaterThanOrEqualTo(48.0));
      expect(btnSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(guideBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CaregiverTermsGuideScreen), findsOneWidget);
      expect(find.text('Caregiver & Clinical Terms Guide'), findsOneWidget);
    });

    testWidgets('HemodialysisCheckInScreen embeds accessible (i) triggers for IDWG, UF Goal, and Thrill & Bruit',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final patient = await harness.createPatient(
        name: 'Robert Davis',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 70.0,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
      );

      await tester.pumpWidget(createTestApp(home: HemodialysisCheckInScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify IDWG info trigger
      final idwgTrigger = find.byKey(const Key('idwg_info_trigger'));
      expect(idwgTrigger, findsOneWidget);
      final idwgSize = tester.getSize(idwgTrigger);
      expect(idwgSize.width, greaterThanOrEqualTo(48.0));
      expect(idwgSize.height, greaterThanOrEqualTo(48.0));

      // Verify UF Goal info trigger
      final ufGoalTrigger = find.byKey(const Key('uf_goal_info_trigger'));
      expect(ufGoalTrigger, findsOneWidget);
      final ufSize = tester.getSize(ufGoalTrigger);
      expect(ufSize.width, greaterThanOrEqualTo(48.0));
      expect(ufSize.height, greaterThanOrEqualTo(48.0));

      // Verify Access Inspection info trigger
      final accessTrigger = find.byKey(const Key('access_inspection_info_trigger'));
      expect(accessTrigger, findsOneWidget);

      // Tap IDWG trigger to open bottom sheet
      await tester.tap(idwgTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Interdialytic Weight Gain (IDWG)'), findsWidgets);
      expect(find.textContaining('< 2.0 to 2.5 kg'), findsOneWidget);

      // Dismiss bottom sheet via Got It button
      final dismissBtn = find.byKey(const Key('bottom_sheet_dismiss_button'));
      await tester.ensureVisible(dismissBtn);
      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      // Verify returned to check-in screen without disrupting workflow
      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsNothing);
      expect(find.byKey(const Key('pre_weight_input')), findsOneWidget);
    });

    testWidgets('FluidHubScreen embeds accessible (i) triggers for Native Urine Balance and Dialytic Fluid Balance',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final patient = await harness.createPatient(
        name: 'Maria Santos',
        diagnosis: ClinicalCondition.hemodialysis.name,
      );

      await tester.pumpWidget(createTestApp(home: FluidHubScreen(patient: patient)));
      await tester.pumpAndSettle();

      final retentionTrigger = find.byKey(const Key('retention_info_trigger'));
      expect(retentionTrigger, findsOneWidget);
      final retSize = tester.getSize(retentionTrigger);
      expect(retSize.width, greaterThanOrEqualTo(48.0));
      expect(retSize.height, greaterThanOrEqualTo(48.0));

      final netBalanceTrigger = find.byKey(const Key('net_balance_info_trigger'));
      expect(netBalanceTrigger, findsOneWidget);

      // Tap Retention trigger
      await tester.tap(retentionTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Native Urine Balance'), findsWidgets);

      // Close bottom sheet
      await tester.tap(find.byKey(const Key('bottom_sheet_close_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsNothing);
    });

    testWidgets('BloodPressureEntryScreen embeds accessible (i) triggers for Fistula Arm Safety and Paired BP Deltas',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final patient = await harness.createPatient(
        name: 'James Wilson',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
      );

      // Record baseline and follow-up to show delta
      final now = DateTime.now().toUtc();
      await harness.database.into(harness.database.bloodPressureLogs).insert(
            BloodPressureLogsCompanion.insert(
              patientId: patient.id,
              systolic: 160,
              diastolic: 95,
              pulse: 84,
              armUsed: 'rightArm',
              recordedAt: now.subtract(const Duration(minutes: 30)),
              isPairedAssessment: const Value(true),
              pairedRole: const Value('baseline'),
            ),
          );

      await harness.database.into(harness.database.bloodPressureLogs).insert(
            BloodPressureLogsCompanion.insert(
              patientId: patient.id,
              systolic: 135,
              diastolic: 80,
              pulse: 78,
              armUsed: 'rightArm',
              recordedAt: now,
              isPairedAssessment: const Value(true),
              pairedRole: const Value('followUp'),
              elapsedMinutes: const Value(30),
              systolicDelta: const Value(-25),
              diastolicDelta: const Value(-15),
              pulseDelta: const Value(-6),
            ),
          );

      await tester.pumpWidget(createTestApp(home: BloodPressureEntryScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Fistula safety trigger
      final fistulaTrigger = find.byKey(const Key('fistula_safety_info_trigger'));
      expect(fistulaTrigger, findsOneWidget);

      await tester.tap(fistulaTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Fistula Arm Safety Flag'), findsWidgets);

      await tester.tap(find.byKey(const Key('bottom_sheet_close_button')));
      await tester.pumpAndSettle();

      // Paired BP delta trigger
      final deltaTrigger = find.byKey(const Key('paired_bp_delta_info_trigger'));
      expect(deltaTrigger, findsOneWidget);

      await tester.tap(deltaTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Paired Anti-Hypertensive BP Assessment'), findsWidgets);
    });

    testWidgets('CatheterLifespanScreen embeds accessible (i) triggers for CAUTI Risk Window and Hematuria Grade',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final patient = await harness.createPatient(
        name: 'Harold Green',
        diagnosis: ClinicalCondition.urologicalCatheter.name,
      );

      // Insert catheter that is overdue (> 14 days) to trigger CAUTI Risk Window banner
      final overdueInsertion = DateTime.now().subtract(const Duration(days: 16));
      await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: overdueInsertion,
        replacementDueDate: overdueInsertion.add(const Duration(days: 14)),
        status: 'active',
      );

      await tester.pumpWidget(createTestApp(home: CatheterLifespanScreen(patient: patient)));
      await tester.pumpAndSettle();

      // CAUTI Risk Window trigger
      final cautiTrigger = find.byKey(const Key('cauti_risk_info_trigger'));
      expect(cautiTrigger, findsOneWidget);

      await tester.tap(cautiTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('CAUTI Risk Window'), findsWidgets);

      await tester.tap(find.byKey(const Key('bottom_sheet_close_button')));
      await tester.pumpAndSettle();

      // 1-Tap Bag Emptied Dialog trigger for Hematuria Grade
      final emptyBagButton = find.byKey(const Key('one_tap_bag_emptied_button'));
      expect(emptyBagButton, findsOneWidget);
      await tester.ensureVisible(emptyBagButton);
      await tester.tap(emptyBagButton);
      await tester.pumpAndSettle();

      final hematuriaTrigger = find.byKey(const Key('hematuria_grade_info_trigger'));
      expect(hematuriaTrigger, findsOneWidget);

      await tester.tap(hematuriaTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Hematuria Grade'), findsWidgets);
    });

    testWidgets('ModularClinicalReportScreen embeds accessible (i) triggers for module configuration',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final patient = await harness.createPatient(
        name: 'Diana Prince',
        diagnosis: ClinicalCondition.hemodialysis.name,
      );

      await tester.pumpWidget(createTestApp(home: ModularClinicalReportScreen(patient: patient)));
      await tester.pumpAndSettle();

      final modulesTrigger = find.byKey(const Key('report_modules_info_trigger'));
      expect(modulesTrigger, findsOneWidget);

      await tester.tap(modulesTrigger);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsWidgets);

      await tester.tap(find.byKey(const Key('bottom_sheet_close_button')));
      await tester.pumpAndSettle();

      // Individual module triggers
      expect(find.byKey(const Key('report_module_info_paired_bp')), findsOneWidget);
      expect(find.byKey(const Key('report_module_info_dual_fluid')), findsOneWidget);
    });
  });
}
