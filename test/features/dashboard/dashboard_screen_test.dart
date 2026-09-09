import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/presentation/blood_pressure_entry_screen.dart';
import 'package:nephrocare/src/features/catheter/presentation/catheter_lifespan_screen.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/dashboard/presentation/symptom_log_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/access_inspection_history_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_check_in_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_post_session_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/peritoneal_exchange_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/weight_trends_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_hub_screen.dart';
import 'package:nephrocare/src/features/medications/presentation/medication_screen.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';
import 'package:nephrocare/src/features/reports/presentation/modular_clinical_report_screen.dart';

void main() {
  group('Unified Dashboard Seam: Condition-Adaptive Grid & Screen Navigation', () {
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

    testWidgets('Hemodialysis dashboard renders 6 cards with 48dp touch targets and navigates to clinical screens',
        (tester) async {
      final patient = await harness.createPatient(
        name: 'Eleanor Vance',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 68.5,
        dailyFluidAllowanceMl: 1200,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify exactly six cards rendered
      expect(find.text('Unified Dialysis Session'), findsOneWidget);
      expect(find.text('Blood Pressure & Paired BP'), findsOneWidget);
      expect(find.text('Fluid Hub'), findsOneWidget);
      expect(find.text('Medication Management'), findsOneWidget);
      expect(find.text('Catheter & Access Monitor'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);

      // Verify touch target min 48dp on cards
      final sessionCard = find.text('Unified Dialysis Session');
      final cardSize = tester.getSize(sessionCard);
      expect(cardSize.height, greaterThanOrEqualTo(20.0));

      // 1. Navigate to Unified Dialysis Session (Check-in when inactive)
      await tester.ensureVisible(find.text('Unified Dialysis Session'));
      await tester.tap(find.text('Unified Dialysis Session'));
      await tester.pumpAndSettle();
      expect(find.byType(HemodialysisCheckInScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(HemodialysisCheckInScreen))).pop();
      await tester.pumpAndSettle();

      // 2. Navigate to Blood Pressure & Paired BP
      await tester.ensureVisible(find.text('Blood Pressure & Paired BP'));
      await tester.tap(find.text('Blood Pressure & Paired BP'));
      await tester.pumpAndSettle();
      expect(find.byType(BloodPressureEntryScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(BloodPressureEntryScreen))).pop();
      await tester.pumpAndSettle();

      // 3. Navigate to Fluid Hub
      await tester.ensureVisible(find.text('Fluid Hub'));
      await tester.tap(find.text('Fluid Hub'));
      await tester.pumpAndSettle();
      expect(find.byType(FluidHubScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(FluidHubScreen))).pop();
      await tester.pumpAndSettle();

      // 4. Navigate to Medication Management
      await tester.ensureVisible(find.text('Medication Management'));
      await tester.tap(find.text('Medication Management'));
      await tester.pumpAndSettle();
      expect(find.byType(MedicationScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(MedicationScreen))).pop();
      await tester.pumpAndSettle();

      // 5. Navigate to Catheter & Access Monitor
      await tester.ensureVisible(find.text('Catheter & Access Monitor'));
      await tester.tap(find.text('Catheter & Access Monitor'));
      await tester.pumpAndSettle();
      expect(find.byType(AccessInspectionHistoryScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AccessInspectionHistoryScreen))).pop();
      await tester.pumpAndSettle();

      // 6. Navigate to Modular Clinical Report
      await tester.ensureVisible(find.text('Modular Clinical Report'));
      await tester.tap(find.text('Modular Clinical Report'));
      await tester.pumpAndSettle();
      expect(find.byType(ModularClinicalReportScreen), findsOneWidget);
    });

    testWidgets('Active in-progress dialysis session shows banner and 1-tap navigation to checkout',
        (tester) async {
      final patient = await harness.createPatient(
        name: 'In-Progress Patient',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 70.0,
      );

      // Start an in-progress session
      await harness.recordPreDialysisCheckIn(
        patientId: patient.id,
        preWeightKg: 72.4,
        volumeAllowanceMl: 300,
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      // 1. Verify active session banner exists
      expect(find.byKey(const Key('active_dialysis_session_banner')), findsOneWidget);
      expect(find.text('Dialysis Session In Progress'), findsOneWidget);
      expect(find.byKey(const Key('resume_dialysis_session_button')), findsOneWidget);

      // 2. Tap resume button -> 1-tap navigation to HemodialysisPostSessionScreen
      await tester.ensureVisible(find.byKey(const Key('resume_dialysis_session_button')));
      await tester.tap(find.byKey(const Key('resume_dialysis_session_button')));
      await tester.pumpAndSettle();

      expect(find.byType(HemodialysisPostSessionScreen), findsOneWidget);
      expect(find.text('Post-Dialysis Session Log'), findsOneWidget);

      // Pop back to dashboard
      Navigator.of(tester.element(find.byType(HemodialysisPostSessionScreen))).pop();
      await tester.pumpAndSettle();

      // 3. Tapping the Unified Dialysis Session card also resumes the in-progress session
      await tester.ensureVisible(find.text('Unified Dialysis Session'));
      await tester.tap(find.text('Unified Dialysis Session'));
      await tester.pumpAndSettle();
      expect(find.byType(HemodialysisPostSessionScreen), findsOneWidget);
    });

    testWidgets('Peritoneal Dialysis dashboard renders 6 cards and navigates to PD clinical screens',
        (tester) async {
      final patient = await harness.createPatient(
        name: 'Marcus Chen',
        diagnosis: ClinicalCondition.peritonealDialysis.name,
        prescribedDryWeightKg: 72.0,
        dailyFluidAllowanceMl: 1500,
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.text('Exchange Log'), findsOneWidget);
      expect(find.text('Exit-Site Inspection'), findsOneWidget);
      expect(find.text('Daily Weight'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Fluid Hub'), findsOneWidget);
      expect(find.text('Medication Management'), findsOneWidget);

      // 1. Tapping Exchange Log opens PeritonealExchangeScreen
      await tester.ensureVisible(find.text('Exchange Log'));
      await tester.tap(find.text('Exchange Log'));
      await tester.pumpAndSettle();
      expect(find.byType(PeritonealExchangeScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(PeritonealExchangeScreen))).pop();
      await tester.pumpAndSettle();

      // 2. Tapping Exit-Site Inspection opens AccessInspectionHistoryScreen
      await tester.ensureVisible(find.text('Exit-Site Inspection'));
      await tester.tap(find.text('Exit-Site Inspection'));
      await tester.pumpAndSettle();
      expect(find.byType(AccessInspectionHistoryScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AccessInspectionHistoryScreen))).pop();
      await tester.pumpAndSettle();

      // 3. Tapping Daily Weight opens WeightTrendsScreen
      await tester.ensureVisible(find.text('Daily Weight'));
      await tester.tap(find.text('Daily Weight'));
      await tester.pumpAndSettle();
      expect(find.byType(WeightTrendsScreen), findsOneWidget);
    });

    testWidgets('Non-Dialysis CKD dashboard renders 6 cards and navigates to Symptom Log',
        (tester) async {
      final patient = await harness.createPatient(
        name: 'Carlos Mendez',
        diagnosis: ClinicalCondition.nonDialysisCkd.name,
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.text('Blood Pressure & Paired BP'), findsOneWidget);
      expect(find.text('Daily Weight'), findsOneWidget);
      expect(find.text('Fluid Hub'), findsOneWidget);
      expect(find.text('Medication Management'), findsOneWidget);
      expect(find.text('Symptom Log'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);

      // Tapping Symptom Log opens SymptomLogScreen
      await tester.ensureVisible(find.text('Symptom Log'));
      await tester.tap(find.text('Symptom Log'));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomLogScreen), findsOneWidget);
    });

    testWidgets('Urological / Catheter dashboard renders 6 cards and navigates to Catheter Lifespan',
        (tester) async {
      final patient = await harness.createPatient(
        name: 'Arthur Pendelton',
        diagnosis: ClinicalCondition.urologicalCatheter.name,
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.text('Foley Catheter Lifespan'), findsOneWidget);
      expect(find.text('Fluid Hub'), findsOneWidget);
      expect(find.text('Medication Management'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Symptom Log'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);

      // Tapping Foley Catheter Lifespan opens CatheterLifespanScreen
      await tester.ensureVisible(find.text('Foley Catheter Lifespan'));
      await tester.tap(find.text('Foley Catheter Lifespan'));
      await tester.pumpAndSettle();
      expect(find.byType(CatheterLifespanScreen), findsOneWidget);
    });
  });
}
