import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/domain/paired_bp_alarm_service.dart';
import 'package:nephrocare/src/features/blood_pressure/presentation/blood_pressure_entry_screen.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';

void main() {
  group('Unified Application & State Seam: Fistula Arm Safety Flag & Blood Pressure Hard Lockout', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Widget createTestApp({Widget? home}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
          pairedBpAlarmServiceProvider.overrideWithValue(harness.pairedBpAlarmService),
        ],
        child: MaterialApp(
          home: home ?? const NephroCareHomePage(),
        ),
      );
    }

    testWidgets(
      'Blood pressure entry screen enforces hard lockout on left arm when left arm fistula is active',
      (WidgetTester tester) async {
        // 1. Seed patient with Arteriovenous Fistula on Left Arm
        final patient = await harness.createPatient(
          name: 'Sarah Connor',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: BloodPressureEntryScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // 2. Verify Fistula Arm Safety Flag banner is prominently displayed
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsOneWidget);
        expect(find.textContaining('Fistula Arm Safety Flag Active'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('fistula_arm_safety_banner')),
            matching: find.textContaining('Left Arm'),
          ),
          findsOneWidget,
        );

        // 3. Verify arm selection lockout:
        // Left arm button is disabled/locked out
        final leftArmButton = find.byKey(const Key('arm_left_button'));
        final rightArmButton = find.byKey(const Key('arm_right_button'));
        expect(leftArmButton, findsOneWidget);
        expect(rightArmButton, findsOneWidget);

        // Verify Left Arm button is disabled (InkWell / ElevatedButton enabled state)
        final elevatedButtonLeft = tester.widget<ElevatedButton>(leftArmButton);
        expect(elevatedButtonLeft.onPressed, isNull);

        // Right Arm is enabled and auto-selected as the safe arm
        final elevatedButtonRight = tester.widget<ElevatedButton>(rightArmButton);
        expect(elevatedButtonRight.onPressed, isNotNull);

        // 4. Fill in blood pressure metrics
        await tester.enterText(find.byKey(const Key('systolic_input')), '135');
        await tester.enterText(find.byKey(const Key('diastolic_input')), '85');
        await tester.enterText(find.byKey(const Key('pulse_input')), '74');
        await tester.pumpAndSettle();

        // Verify touch targets are at least 48dp
        final saveButton = find.byKey(const Key('save_bp_button'));
        final saveButtonSize = tester.getSize(saveButton);
        expect(saveButtonSize.height, greaterThanOrEqualTo(48.0));
        expect(saveButtonSize.width, greaterThanOrEqualTo(48.0));

        // 5. Submit reading
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // 6. Verify record is persisted in SQLite with UUIDv4 and safe arm
        final logs = await harness.database.select(harness.database.bloodPressureLogs).get();
        expect(logs.length, equals(1));
        expect(logs.first.systolic, equals(135));
        expect(logs.first.diastolic, equals(85));
        expect(logs.first.pulse, equals(74));
        expect(logs.first.armUsed, equals('rightArm'));
        expect(logs.first.isSafeArm, isTrue);

        // 7. Verify hemodynamic trend item surfaces reactively on screen
        expect(find.text('135/85 mmHg'), findsOneWidget);
        expect(find.textContaining('74 bpm'), findsOneWidget);
        expect(find.textContaining('Right Arm'), findsWidgets);
      },
    );

    testWidgets(
      'Blood pressure entry allows both arms when patient has non-arm vascular access',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'James Kirk',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.tunneledDialysisCentralLine.name,
          fistulaArmLocation: AccessLocation.chest.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: BloodPressureEntryScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // No safety lockout banner for chest line
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsNothing);

        // Both Left Arm and Right Arm are enabled
        final elevatedButtonLeft = tester.widget<ElevatedButton>(find.byKey(const Key('arm_left_button')));
        final elevatedButtonRight = tester.widget<ElevatedButton>(find.byKey(const Key('arm_right_button')));
        expect(elevatedButtonLeft.onPressed, isNotNull);
        expect(elevatedButtonRight.onPressed, isNotNull);

        // Select Left Arm and submit
        await tester.tap(find.byKey(const Key('arm_left_button')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('systolic_input')), '120');
        await tester.enterText(find.byKey(const Key('diastolic_input')), '80');
        await tester.enterText(find.byKey(const Key('pulse_input')), '68');
        await tester.pumpAndSettle();

        final saveButton = find.byKey(const Key('save_bp_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        final logs = await harness.database.select(harness.database.bloodPressureLogs).get();
        expect(logs.length, equals(1));
        expect(logs.first.armUsed, equals('leftArm'));
      },
    );

    testWidgets(
      'Blood pressure entry allows unrestricted arm selection for Non-Tunneled Temporary Line in Neck and Thigh/Groin',
      (WidgetTester tester) async {
        // 1. Patient with Non-Tunneled line in the Neck (Internal Jugular)
        final neckPatient = await harness.createPatient(
          name: 'Uhura Neck',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
          fistulaArmLocation: AccessLocation.neck.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: BloodPressureEntryScreen(patient: neckPatient),
          ),
        );
        await tester.pumpAndSettle();

        // Banner must NOT appear
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsNothing);

        // Both Left Arm and Right Arm are clickable
        expect(tester.widget<ElevatedButton>(find.byKey(const Key('arm_left_button'))).onPressed, isNotNull);
        expect(tester.widget<ElevatedButton>(find.byKey(const Key('arm_right_button'))).onPressed, isNotNull);

        // Select Right Arm and submit
        await tester.tap(find.byKey(const Key('arm_right_button')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('systolic_input')), '118');
        await tester.enterText(find.byKey(const Key('diastolic_input')), '76');
        await tester.enterText(find.byKey(const Key('pulse_input')), '65');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('save_bp_button')));
        await tester.pumpAndSettle();

        // 2. Patient with Non-Tunneled line in Thigh/Groin (Femoral)
        final femoralPatient = await harness.createPatient(
          name: 'Sulu Femoral',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
          fistulaArmLocation: AccessLocation.thighGroin.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: BloodPressureEntryScreen(patient: femoralPatient),
          ),
        );
        await tester.pumpAndSettle();

        // Banner must NOT appear
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsNothing);

        // Both arms clickable
        expect(tester.widget<ElevatedButton>(find.byKey(const Key('arm_left_button'))).onPressed, isNotNull);
        expect(tester.widget<ElevatedButton>(find.byKey(const Key('arm_right_button'))).onPressed, isNotNull);

        // Select Left Arm and submit
        await tester.tap(find.byKey(const Key('arm_left_button')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('systolic_input')), '124');
        await tester.enterText(find.byKey(const Key('diastolic_input')), '82');
        await tester.enterText(find.byKey(const Key('pulse_input')), '70');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('save_bp_button')));
        await tester.pumpAndSettle();

        final logs = await harness.database.select(harness.database.bloodPressureLogs).get();
        expect(logs.length, equals(2));
        expect(logs[0].patientId, equals(neckPatient.id));
        expect(logs[0].armUsed, equals('rightArm'));
        expect(logs[1].patientId, equals(femoralPatient.id));
        expect(logs[1].armUsed, equals('leftArm'));
      },
    );

    testWidgets(
      'Blood pressure entry enforces hard lockout on right arm when right arm fistula is active',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Right Arm Patient',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.rightArm.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: BloodPressureEntryScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // Banner is displayed showing Right Arm
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsOneWidget);
        expect(find.textContaining('Right Arm'), findsWidgets);

        // Right arm is locked out (onPressed is null), Left arm is enabled
        final leftArmButton = tester.widget<ElevatedButton>(find.byKey(const Key('arm_left_button')));
        final rightArmButton = tester.widget<ElevatedButton>(find.byKey(const Key('arm_right_button')));
        expect(rightArmButton.onPressed, isNull);
        expect(leftArmButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'Dashboard Blood Pressure clinical card navigates to BloodPressureEntryScreen',
      (WidgetTester tester) async {
        await harness.createPatient(
          name: 'Eleanor Vance',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        await tester.pumpWidget(
          createTestApp(),
        );
        await tester.pumpAndSettle();

        // Dashboard is rendered with 6 cards
        expect(find.text('NephroCare'), findsOneWidget);
        expect(find.text('Blood Pressure & Paired BP'), findsOneWidget);

        // Tap the Blood Pressure card
        await tester.tap(find.text('Blood Pressure & Paired BP'));
        await tester.pumpAndSettle();

        // Should navigate to BloodPressureEntryScreen
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsOneWidget);
        expect(find.byKey(const Key('save_bp_button')), findsOneWidget);
      },
    );

    testWidgets(
      'BloodPressureEntryScreen renders pending follow-up banner and allows logging follow-up measurement pre-populated with baseline reference values',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Sarah Paired',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        final med = await harness.createMedication(
          patientId: patient.id,
          name: 'Amlodipine',
          dosage: '10 mg',
          frequency: 'Daily',
          isAntiHypertensive: true,
        );

        final admin = await harness.recordMedicationAdministration(
          patientId: patient.id,
          medicationId: med.id,
        );

        final baseline = await harness.recordBaselineBloodPressure(
          patientId: patient.id,
          medicationAdministrationId: admin.id,
          medicationName: med.name,
          systolic: 162,
          diastolic: 100,
          pulse: 82,
          armUsed: 'rightArm',
        );

        await tester.pumpWidget(
          createTestApp(
            home: BloodPressureEntryScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // Verify pending follow-up banner is rendered
        expect(find.byKey(const Key('pending_followup_banner')), findsOneWidget);
        expect(find.textContaining('Follow-Up BP Measurement Due'), findsOneWidget);
        expect(find.textContaining('162/100 mmHg'), findsWidgets);

        // Tap log follow-up measurement
        final followUpBtn = find.byKey(const Key('entry_log_paired_followup_button'));
        expect(followUpBtn, findsOneWidget);
        await tester.tap(followUpBtn);
        await tester.pumpAndSettle();

        // Verify follow-up prompt dialog opened pre-populated with baseline reference values
        expect(find.text('Follow-Up Blood Pressure'), findsOneWidget);
        expect(find.text('Baseline Reference Values'), findsOneWidget);
        expect(find.textContaining('162/100 mmHg'), findsWidgets);

        // Enter follow-up values
        await tester.enterText(find.byKey(const Key('paired_followup_systolic_input')), '132');
        await tester.enterText(find.byKey(const Key('paired_followup_diastolic_input')), '82');
        await tester.enterText(find.byKey(const Key('paired_followup_pulse_input')), '74');

        await tester.tap(find.byKey(const Key('save_paired_followup_button')));
        await tester.pumpAndSettle();

        // Verify pending banner disappears
        expect(find.byKey(const Key('pending_followup_banner')), findsNothing);

        // Verify trends list displays Follow-Up badge and calculated hemodynamic deltas
        expect(find.textContaining('Follow-Up'), findsWidgets);
        expect(find.textContaining('Hemodynamic Delta: -30/-18 mmHg'), findsOneWidget);

        // Verify repository stores deltas
        final pairedAssessments = await harness.getPairedAssessments(patient.id);
        expect(pairedAssessments.length, equals(1));
        final pair = pairedAssessments.first;
        expect(pair.baseline.id, equals(baseline.id));
        expect(pair.isCompleted, isTrue);
        expect(pair.systolicDelta, equals(-30));
        expect(pair.diastolicDelta, equals(-18));
      },
    );

    testWidgets(
      'DashboardScreen displays paired follow-up alert card when anti-hypertensive follow-up is due',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Dashboard Paired Patient',
          diagnosis: ClinicalCondition.hemodialysis.name,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        final med = await harness.createMedication(
          patientId: patient.id,
          name: 'Lisinopril',
          dosage: '20 mg',
          frequency: 'Daily',
          isAntiHypertensive: true,
        );

        final admin = await harness.recordMedicationAdministration(
          patientId: patient.id,
          medicationId: med.id,
        );

        await harness.recordBaselineBloodPressure(
          patientId: patient.id,
          medicationAdministrationId: admin.id,
          medicationName: med.name,
          systolic: 170,
          diastolic: 104,
          pulse: 88,
          armUsed: 'rightArm',
        );

        await tester.pumpWidget(
          createTestApp(),
        );
        await tester.pumpAndSettle();

        // Verify dashboard alert card is visible
        expect(find.byKey(const Key('dashboard_paired_bp_alert_card')), findsOneWidget);
        expect(find.text('Follow-Up Blood Pressure Due'), findsOneWidget);
        expect(find.textContaining('170/104 mmHg'), findsWidgets);

        // Tap action on dashboard alert card
        final logBtn = find.byKey(const Key('dashboard_log_paired_followup_button'));
        expect(logBtn, findsOneWidget);
        await tester.tap(logBtn);
        await tester.pumpAndSettle();

        // Verify dialog opens
        expect(find.text('Follow-Up Blood Pressure'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('paired_followup_systolic_input')), '138');
        await tester.enterText(find.byKey(const Key('paired_followup_diastolic_input')), '84');
        await tester.enterText(find.byKey(const Key('paired_followup_pulse_input')), '78');

        await tester.tap(find.byKey(const Key('save_paired_followup_button')));
        await tester.pumpAndSettle();

        // Verify dashboard alert card is dismissed after follow-up
        expect(find.byKey(const Key('dashboard_paired_bp_alert_card')), findsNothing);
      },
    );
  });
}
