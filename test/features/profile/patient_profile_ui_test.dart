import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';
import 'package:nephrocare/src/features/profile/data/patient_repository.dart';

void main() {
  group('Unified Application & State Seam: Profile Setup & Condition-Adaptive Grid', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: const NephroCareApp(),
      );
    }

    testWidgets('Empty profile initiates Patient Profile Setup flow, saves to Drift, and renders Hemodialysis 6-card grid',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 1. Initial State: Profile setup form is shown because no patient exists
      expect(find.text('Patient Profile Setup'), findsOneWidget);
      expect(find.byKey(const Key('patient_name_input')), findsOneWidget);
      expect(find.byKey(const Key('diagnosis_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('dry_weight_input')), findsOneWidget);
      expect(find.byKey(const Key('fluid_allowance_input')), findsOneWidget);
      expect(find.byKey(const Key('access_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('save_profile_button')), findsOneWidget);

      // 2. Fill out Patient Profile Setup
      await tester.enterText(find.byKey(const Key('patient_name_input')), 'Eleanor Vance');
      await tester.pumpAndSettle();

      // Select Hemodialysis condition
      await tester.tap(find.byKey(const Key('diagnosis_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hemodialysis').last);
      await tester.pumpAndSettle();

      // Enter Dry Weight & Fluid Allowance
      await tester.enterText(find.byKey(const Key('dry_weight_input')), '68.5');
      await tester.enterText(find.byKey(const Key('fluid_allowance_input')), '1200');
      await tester.pumpAndSettle();

      // Select Vascular Access Type: Arteriovenous Fistula
      await tester.ensureVisible(find.byKey(const Key('access_type_dropdown')));
      await tester.tap(find.byKey(const Key('access_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arteriovenous Fistula').last);
      await tester.pumpAndSettle();

      // Select Access Location: Left Arm
      await tester.ensureVisible(find.byKey(const Key('access_location_dropdown')));
      await tester.tap(find.byKey(const Key('access_location_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Left Arm').last);
      await tester.pumpAndSettle();

      // 3. Submit profile
      final saveButton = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveButton);
      // Verify touch target is at least 48dp
      final buttonSize = tester.getSize(saveButton);
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 4. Verify persisted in SQLite database
      final repository = PatientRepository(harness.database);
      final activePatient = await repository.getActivePatient();
      expect(activePatient, isNotNull);
      expect(activePatient!.name, equals('Eleanor Vance'));
      expect(activePatient.diagnosis, equals('hemodialysis'));
      expect(activePatient.prescribedDryWeightKg, equals(68.5));
      expect(activePatient.dailyFluidAllowanceMl, equals(1200));
      expect(activePatient.vascularAccessType, equals('arteriovenousFistula'));
      expect(activePatient.fistulaArmLocation, equals('leftArm'));

      // 5. Verify reactive transition to primary Condition-Adaptive Grid
      expect(find.text('Patient Profile Setup'), findsNothing);
      expect(find.text('Eleanor Vance'), findsOneWidget);
      expect(find.text('Hemodialysis'), findsOneWidget);

      // Verify Fistula Arm Safety Flag warning is displayed for Left Arm
      expect(find.textContaining('Fistula Arm Safety Flag Active'), findsOneWidget);
      expect(find.textContaining('Left Arm'), findsOneWidget);

      // Verify exactly six clinical action cards for Hemodialysis
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Post-Dialysis Log'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Fluid Hub'), findsOneWidget);
      expect(find.text('Medication & Binders'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);
    });

    testWidgets('Reactive rendering updates Condition-Adaptive Grid when patient condition changes',
        (WidgetTester tester) async {
      // 1. Seed with Peritoneal Dialysis patient
      await harness.createPatient(
        name: 'Marcus Chen',
        diagnosis: ClinicalCondition.peritonealDialysis.name,
        prescribedDryWeightKg: 72.0,
        dailyFluidAllowanceMl: 1500,
        vascularAccessType: 'peritonealDialysisAccess',
        fistulaArmLocation: 'abdomen',
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Peritoneal Dialysis cards
      expect(find.text('Marcus Chen'), findsOneWidget);
      expect(find.text('Exchange Log'), findsOneWidget);
      expect(find.text('Exit-Site Inspection'), findsOneWidget);
      expect(find.text('Daily Weight & Dry Weight'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('24h Fluid Balance'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);

      // 2. Reactively switch condition to Non-Dialysis CKD
      final repository = PatientRepository(harness.database);
      final current = await repository.getActivePatient();
      await repository.updatePatientProfile(
        id: current!.id,
        name: 'Marcus Chen',
        diagnosis: ClinicalCondition.nonDialysisCkd.name,
        dailyFluidAllowanceMl: 1800,
      );

      await tester.pumpAndSettle();

      // Verify reactively updated 6 Non-Dialysis CKD cards
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Daily Weight'), findsOneWidget);
      expect(find.text('Fluid Allowance Tracker'), findsOneWidget);
      expect(find.text('Medication & Binders'), findsOneWidget);
      expect(find.text('Symptom Log'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);

      // 3. Reactively switch condition to Urological / Catheter
      await repository.updatePatientProfile(
        id: current.id,
        name: 'Marcus Chen',
        diagnosis: ClinicalCondition.urologicalCatheter.name,
        dailyFluidAllowanceMl: 2000,
      );

      await tester.pumpAndSettle();

      // Verify reactively updated 6 Urological / Catheter cards
      expect(find.text('Foley Catheter Lifespan'), findsOneWidget);
      expect(find.text('Urine Evacuation'), findsOneWidget);
      expect(find.text('Fluid Intake'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Symptom Log'), findsOneWidget);
      expect(find.text('Modular Clinical Report'), findsOneWidget);
    });

    testWidgets('Profile setup designates Caregiver Mirror and dashboard displays Caregiver Mirror badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Fill out setup form
      await tester.enterText(find.byKey(const Key('patient_name_input')), 'Grandpa Joe');
      await tester.pumpAndSettle();

      // Select Urological / Catheter condition
      await tester.tap(find.byKey(const Key('diagnosis_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Urological / Catheter').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fluid_allowance_input')), '2000');
      await tester.pumpAndSettle();

      // Toggle Caregiver Mirror
      final mirrorSwitch = find.byKey(const Key('caregiver_mirror_switch'));
      expect(mirrorSwitch, findsOneWidget);
      await tester.ensureVisible(mirrorSwitch);
      await tester.tap(mirrorSwitch);
      await tester.pumpAndSettle();

      // Save profile
      final saveButton = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify dashboard displays Grandpa Joe and Caregiver Mirror badge
      expect(find.text('Grandpa Joe'), findsOneWidget);
      expect(find.byKey(const Key('caregiver_mirror_badge')), findsOneWidget);
      expect(find.text('Caregiver Mirror'), findsOneWidget);
    });

    testWidgets('Profile management allows switching between multiple patient profiles and reactively reconfigures Condition-Adaptive Grid',
        (WidgetTester tester) async {
      final now = DateTime.now().toUtc();

      // 1. Seed two patients: Eleanor Vance (Hemodialysis, direct patient) and Marcus Chen (Urological Catheter, Caregiver Mirror)
      final patient1 = await harness.createPatient(
        name: 'Eleanor Vance',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 68.5,
        dailyFluidAllowanceMl: 1200,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        isCaregiverMirror: false,
        createdAt: now.subtract(const Duration(seconds: 10)),
        updatedAt: now.subtract(const Duration(seconds: 5)),
      );

      final patient2 = await harness.createPatient(
        name: 'Marcus Chen',
        diagnosis: ClinicalCondition.urologicalCatheter.name,
        dailyFluidAllowanceMl: 2000,
        isCaregiverMirror: true,
        createdAt: now.subtract(const Duration(seconds: 8)),
        updatedAt: now.subtract(const Duration(seconds: 10)),
      );

      // Make Eleanor Vance active initially
      await harness.switchActivePatient(patient1.id, asOf: now.subtract(const Duration(seconds: 2)));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify currently active is Eleanor Vance with Hemodialysis 6 cards
      expect(find.text('Eleanor Vance'), findsOneWidget);
      expect(find.text('Hemodialysis'), findsOneWidget);
      expect(find.byKey(const Key('caregiver_mirror_badge')), findsNothing);
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Post-Dialysis Log'), findsOneWidget);

      // 2. Open Profile Management screen from Dashboard AppBar
      final manageProfilesBtn = find.byKey(const Key('manage_profiles_button'));
      expect(manageProfilesBtn, findsOneWidget);
      await tester.tap(manageProfilesBtn);
      await tester.pumpAndSettle();

      // Verify Profile Management Screen shows both profiles
      expect(find.text('Profiles & Caregiver Mirrors'), findsOneWidget);
      expect(find.text('Eleanor Vance'), findsOneWidget);
      expect(find.text('Marcus Chen'), findsOneWidget);
      expect(find.byKey(Key('profile_item_${patient1.id}')), findsOneWidget);
      expect(find.byKey(Key('profile_item_${patient2.id}')), findsOneWidget);

      // Verify Marcus Chen has Caregiver Mirror badge in list
      expect(find.byKey(Key('mirror_badge_${patient2.id}')), findsOneWidget);

      // 3. Switch active profile to Marcus Chen
      await tester.tap(find.byKey(Key('profile_item_${patient2.id}')));
      await tester.pumpAndSettle();

      // 4. Verify Dashboard reactively reconfigures to Marcus Chen and Urological Catheter grid
      expect(find.text('Marcus Chen'), findsOneWidget);
      expect(find.text('Urological / Catheter'), findsOneWidget);
      expect(find.byKey(const Key('caregiver_mirror_badge')), findsOneWidget);

      // Verify Urological Catheter clinical action cards
      expect(find.text('Foley Catheter Lifespan'), findsOneWidget);
      expect(find.text('Urine Evacuation'), findsOneWidget);
      expect(find.text('Fluid Intake'), findsOneWidget);
      expect(find.text('Check-in'), findsNothing); // Hemodialysis check-in gone!
    });

    testWidgets('Profile setup and editing permit selection of Non-Tunneled Temporary Dialysis Lines with neck and thigh/groin locations',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 1. Initial Setup: Create patient with Non-Tunneled Temporary Dialysis Line in the Neck
      await tester.enterText(find.byKey(const Key('patient_name_input')), 'Montgomery Scott');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('diagnosis_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hemodialysis').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('dry_weight_input')), '75.0');
      await tester.enterText(find.byKey(const Key('fluid_allowance_input')), '1000');
      await tester.pumpAndSettle();

      // Select Vascular Access Type: Non-Tunneled Temporary Dialysis Line (Vas-Cath)
      await tester.ensureVisible(find.byKey(const Key('access_type_dropdown')));
      await tester.tap(find.byKey(const Key('access_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Non-Tunneled Temporary Dialysis Line (Vas-Cath)').last);
      await tester.pumpAndSettle();

      // Select Access Location: Neck (Internal Jugular)
      await tester.ensureVisible(find.byKey(const Key('access_location_dropdown')));
      await tester.tap(find.byKey(const Key('access_location_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neck (Internal Jugular)').last);
      await tester.pumpAndSettle();

      // Submit profile
      final saveButton = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      // Dismiss SnackBar so it does not obscure buttons in subsequent screens
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify persisted in Drift SQLite
      final repository = PatientRepository(harness.database);
      final activePatient = await repository.getActivePatient();
      expect(activePatient, isNotNull);
      expect(activePatient!.name, equals('Montgomery Scott'));
      expect(activePatient.vascularAccessType, equals(VascularAccessType.nonTunneledTemporaryDialysisLine.name));
      expect(activePatient.fistulaArmLocation, equals(AccessLocation.neck.name));

      // Verify Dashboard does NOT display Fistula Arm Safety Flag banner for neck access
      expect(find.text('Montgomery Scott'), findsOneWidget);
      expect(find.textContaining('Fistula Arm Safety Flag Active'), findsNothing);

      // 2. Edit Profile: Change location to Thigh / Groin (Femoral)
      await tester.tap(find.byTooltip('Edit Patient Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Patient Profile'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('access_location_dropdown')));
      await tester.tap(find.byKey(const Key('access_location_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thigh / Groin (Femoral)').last);
      await tester.pumpAndSettle();

      final updateButton = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify updated in Drift SQLite
      final updatedPatient = await repository.getActivePatient();
      expect(updatedPatient, isNotNull);
      expect(updatedPatient!.fistulaArmLocation, equals(AccessLocation.thighGroin.name));

      // Verify Dashboard does NOT display Fistula Arm Safety Flag banner for thigh/groin access
      expect(find.textContaining('Fistula Arm Safety Flag Active'), findsNothing);
    });
  });
}
