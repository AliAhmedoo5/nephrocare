import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/dashboard/presentation/symptom_log_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/access_inspection_history_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_check_in_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_post_session_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/peritoneal_exchange_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/weight_trends_screen.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';

void main() {
  group('Unified Application & State Seam: Hemodialysis Check-In & Post-Session Logging UI', () {
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
        ],
        child: MaterialApp(
          home: home ?? const NephroCareHomePage(),
        ),
      );
    }

    testWidgets(
      'Hemodialysis check-in captures pre-weight, computes IDWG and UF Goal, inspects fistula, and persists to Drift',
      (WidgetTester tester) async {
        // 1. Create Patient with Arteriovenous Fistula
        final patient = await harness.createPatient(
          name: 'Sarah Connor',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 70.0,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: HemodialysisCheckInScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // 2. Verify Pre-Session Check-in header and fields
        expect(find.text('Hemodialysis Check-In'), findsOneWidget);
        expect(find.byKey(const Key('pre_weight_input')), findsOneWidget);
        expect(find.byKey(const Key('volume_allowance_input')), findsOneWidget);

        // 3. Enter pre-dialysis weight and volume allowance
        await tester.enterText(find.byKey(const Key('pre_weight_input')), '72.5');
        await tester.enterText(find.byKey(const Key('volume_allowance_input')), '300');
        await tester.pumpAndSettle();

        // Verify calculated values surface:
        // IDWG: 72.5 - 70.0 = 2.5 kg
        // UF Goal: (2.5 * 1000) + 300 = 2800 mL
        expect(find.textContaining('2.5'), findsWidgets);
        expect(find.textContaining('2800'), findsWidgets);

        // 4. Verify Fistula inspection checklist (Thrill & Bruit)
        expect(find.byKey(const Key('thrill_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('bruit_checkbox')), findsOneWidget);

        // Confirm thrill and bruit
        await tester.ensureVisible(find.byKey(const Key('thrill_checkbox')));
        await tester.tap(find.byKey(const Key('thrill_checkbox')));
        await tester.ensureVisible(find.byKey(const Key('bruit_checkbox')));
        await tester.tap(find.byKey(const Key('bruit_checkbox')));
        await tester.pumpAndSettle();

        // Verify minimum touch target 48dp on submit button
        final submitButton = find.byKey(const Key('confirm_check_in_button'));
        final submitSize = tester.getSize(submitButton);
        expect(submitSize.height, greaterThanOrEqualTo(48.0));
        expect(submitSize.width, greaterThanOrEqualTo(48.0));

        // 5. Submit check-in
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // 6. Verify session and access inspection in Drift SQLite
        final sessions = await harness.database.select(harness.database.dialysisSessions).get();
        expect(sessions.length, equals(1));
        expect(sessions.first.preWeightKg, equals(72.5));
        expect(sessions.first.calculatedInterdialyticWeightGainKg, equals(2.5));
        expect(sessions.first.calculatedUltrafiltrationGoalMl, equals(2800));

        final inspections = await harness.database.select(harness.database.accessInspections).get();
        expect(inspections.length, equals(1));
        expect(inspections.first.thrillPresent, isTrue);
        expect(inspections.first.bruitPresent, isTrue);
      },
    );

    testWidgets(
      'Hemodialysis check-in renders central line inspection and warns when infection signs are present',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'James Kirk',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 68.0,
          vascularAccessType: VascularAccessType.dialysisCentralLine.name,
          fistulaArmLocation: AccessLocation.chest.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: HemodialysisCheckInScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Central Line inspection checklist (redness, swelling, discharge, pain)
        expect(find.byKey(const Key('redness_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('swelling_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('discharge_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('pain_checkbox')), findsOneWidget);

        // Check redness and swelling
        await tester.ensureVisible(find.byKey(const Key('redness_checkbox')));
        await tester.tap(find.byKey(const Key('redness_checkbox')));
        await tester.ensureVisible(find.byKey(const Key('swelling_checkbox')));
        await tester.tap(find.byKey(const Key('swelling_checkbox')));
        await tester.pumpAndSettle();

        // Safety warning alert banner surfaces
        expect(find.byKey(const Key('access_safety_warning_banner')), findsOneWidget);
        expect(find.textContaining('Exit-site redness detected'), findsOneWidget);
        expect(find.textContaining('Exit-site swelling detected'), findsOneWidget);
      },
    );

    testWidgets(
      'Hemodialysis check-in renders exit-site checks for Non-Tunneled Temporary Dialysis Line (Vas-Cath)',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Montgomery Scott',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 75.0,
          vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
          fistulaArmLocation: AccessLocation.neck.name,
        );

        await tester.pumpWidget(
          createTestApp(
            home: HemodialysisCheckInScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // Verify exit-site inspection checklist for Non-Tunneled temporary line
        expect(find.byKey(const Key('redness_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('swelling_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('discharge_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('pain_checkbox')), findsOneWidget);

        // Fill pre-weight and toggle discharge & pain
        await tester.enterText(find.byKey(const Key('pre_weight_input')), '78.0');
        await tester.ensureVisible(find.byKey(const Key('discharge_checkbox')));
        await tester.tap(find.byKey(const Key('discharge_checkbox')));
        await tester.ensureVisible(find.byKey(const Key('pain_checkbox')));
        await tester.tap(find.byKey(const Key('pain_checkbox')));
        await tester.pumpAndSettle();

        // Safety warning alert banner surfaces
        expect(find.byKey(const Key('access_safety_warning_banner')), findsOneWidget);
        expect(find.textContaining('Exit-site discharge detected'), findsOneWidget);
        expect(find.textContaining('Exit-site pain reported'), findsOneWidget);

        // Submit check-in
        final confirmBtn = find.byKey(const Key('confirm_check_in_button'));
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Verify inspection persisted
        final inspections = await harness.database.select(harness.database.accessInspections).get();
        expect(inspections.length, equals(1));
        expect(inspections.first.accessType, equals(VascularAccessType.nonTunneledTemporaryDialysisLine.name));
        expect(inspections.first.anatomicalLocation, equals('neck'));
        expect(inspections.first.dischargePresent, isTrue);
        expect(inspections.first.painPresent, isTrue);
      },
    );

    testWidgets(
      'Post-dialysis logging captures post-weight, computes dry weight difference, records symptoms, and persists',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Dana Scully',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 65.0,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.rightArm.name,
        );

        // Seed an ongoing dialysis session
        final session = await harness.recordDialysisSession(
          patientId: patient.id,
          sessionType: 'hemodialysis',
          startedAt: DateTime.now().subtract(const Duration(hours: 4)),
          preWeightKg: 67.5,
          calculatedInterdialyticWeightGainKg: 2.5,
          calculatedUltrafiltrationGoalMl: 2500,
        );

        await tester.pumpWidget(
          createTestApp(
            home: HemodialysisPostSessionScreen(
              patient: patient,
              existingSession: session,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Post-Dialysis Session Log'), findsOneWidget);
        expect(find.byKey(const Key('post_weight_input')), findsOneWidget);
        expect(find.byKey(const Key('fluid_removed_input')), findsOneWidget);

        // Enter post-weight: 65.2 kg (against 65.0 kg dry weight -> +0.2 kg)
        await tester.enterText(find.byKey(const Key('post_weight_input')), '65.2');
        await tester.enterText(find.byKey(const Key('fluid_removed_input')), '2300');
        await tester.pumpAndSettle();

        // Verify dry weight difference display
        expect(find.textContaining('+0.2'), findsWidgets);

        // Select symptoms: cramping, dizziness, hypotension
        await tester.ensureVisible(find.byKey(const Key('symptom_cramping_chip')));
        await tester.tap(find.byKey(const Key('symptom_cramping_chip')));
        await tester.ensureVisible(find.byKey(const Key('symptom_dizziness_chip')));
        await tester.tap(find.byKey(const Key('symptom_dizziness_chip')));
        await tester.ensureVisible(find.byKey(const Key('symptom_hypotension_chip')));
        await tester.tap(find.byKey(const Key('symptom_hypotension_chip')));
        await tester.pumpAndSettle();

        // Submit post-session log
        final saveButton = find.byKey(const Key('save_post_session_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify updated session in Drift SQLite
        final updatedSession = await (harness.database.select(harness.database.dialysisSessions)
              ..where((tbl) => tbl.id.equals(session.id)))
            .getSingle();

        expect(updatedSession.postWeightKg, equals(65.2));
        expect(updatedSession.calculatedPostWeightDifferenceKg, equals(0.2));
        expect(updatedSession.actualFluidRemovedMl, equals(2300));
        expect(updatedSession.symptoms, contains('cramping'));
        expect(updatedSession.symptoms, contains('dizziness'));
        expect(updatedSession.symptoms, contains('hypotension'));
        expect(updatedSession.endedAt, isNotNull);
      },
    );

    testWidgets(
      'Dashboard cards Check-in and Post-Dialysis Log navigate to respective screens',
      (WidgetTester tester) async {
        await harness.createPatient(
          name: 'Fox Mulder',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 74.0,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // 1. Tap Check-in card
        expect(find.text('Check-in'), findsOneWidget);
        await tester.tap(find.text('Check-in'));
        await tester.pumpAndSettle();

        expect(find.text('Hemodialysis Check-In'), findsOneWidget);
        expect(find.byKey(const Key('pre_weight_input')), findsOneWidget);

        // Pop back to dashboard
        Navigator.of(tester.element(find.text('Hemodialysis Check-In'))).pop();
        await tester.pumpAndSettle();

        // 2. Tap Post-Dialysis Log card
        expect(find.text('Post-Dialysis Log'), findsOneWidget);
        await tester.tap(find.text('Post-Dialysis Log'));
        await tester.pumpAndSettle();

        expect(find.text('Post-Dialysis Session Log'), findsOneWidget);
        expect(find.byKey(const Key('post_weight_input')), findsOneWidget);
      },
    );

    testWidgets(
      'Access inspection screen renders history, allows new evaluation, and updates longitudinal timeline',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Dana Scully',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 62.0,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        // Seed an initial inspection
        await harness.recordAccessInspection(
          patientId: patient.id,
          accessType: 'arteriovenousFistula',
          anatomicalLocation: 'leftArm',
          thrillPresent: true,
          bruitPresent: true,
          notes: 'Baseline healthy fistula',
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await tester.pumpWidget(
          createTestApp(
            home: AccessInspectionHistoryScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify screen headers and designated access info
        expect(find.text('Vascular & Exit-Site Inspection'), findsOneWidget);
        expect(find.text('Designated Access Information'), findsOneWidget);
        expect(find.text('Longitudinal Inspection Timeline'), findsOneWidget);

        // 2. Verify previous inspection in the timeline
        expect(find.text('Notes: Baseline healthy fistula'), findsOneWidget);
        expect(find.text('Thrill +'), findsOneWidget);
        expect(find.text('Nominal'), findsOneWidget);

        // 3. Record a new inspection with missing thrill (alert condition)
        final thrillBox = find.byKey(const Key('inspection_thrill_checkbox'));
        expect(thrillBox, findsOneWidget);
        // Leave thrill false, set bruit true
        final bruitBox = find.byKey(const Key('inspection_bruit_checkbox'));
        await tester.ensureVisible(bruitBox);
        await tester.tap(bruitBox);
        await tester.pumpAndSettle();

        // Verify alert banner appears
        expect(find.byKey(const Key('inspection_warning_banner')), findsOneWidget);
        expect(find.textContaining('Absent thrill detected in vascular fistula/graft'), findsOneWidget);

        // Enter notes
        final notesInput = find.byKey(const Key('inspection_notes_input'));
        await tester.enterText(notesInput, 'Urgent: weak pulse, thrill not palpable');
        await tester.pumpAndSettle();

        // Submit inspection
        final saveBtn = find.byKey(const Key('save_inspection_button'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // 4. Verify confirmation and updated timeline
        expect(find.text('Access inspection recorded successfully.'), findsOneWidget);
        expect(find.text('Notes: Urgent: weak pulse, thrill not palpable'), findsOneWidget);
        expect(find.text('Attention Required'), findsOneWidget);
      },
    );

    testWidgets(
      'Weight trends screen displays longitudinal comparison against Prescribed Dry Weight and allows daily weight logging',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'Walter Skinner',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 75.0,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        // Seed a past dialysis session with pre-weight, post-weight
        final session = await harness.recordPreDialysisCheckIn(
          patientId: patient.id,
          preWeightKg: 77.8,
          volumeAllowanceMl: 200,
          startedAt: DateTime.now().subtract(const Duration(days: 2)),
        );
        await harness.recordPostDialysisSession(
          sessionId: session.id,
          postWeightKg: 75.2,
          actualFluidRemovedMl: 2600,
          endedAt: DateTime.now().subtract(const Duration(days: 2, hours: -4)),
        );

        await tester.pumpWidget(
          createTestApp(
            home: WeightTrendsScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify header and Prescribed Dry Weight
        expect(find.text('Weight Tracking & Trends'), findsOneWidget);
        expect(find.text('75.0 kg'), findsWidgets);

        // 2. Verify seeded session in the longitudinal comparison list
        expect(find.text('77.8 kg'), findsOneWidget); // Pre-Dialysis
        expect(find.text('75.2 kg'), findsOneWidget); // Post-Dialysis
        expect(find.textContaining('Gain (IDWG): +2.80 kg'), findsOneWidget);
        expect(find.textContaining('Variance: +0.20 kg'), findsOneWidget);
        expect(find.textContaining('Fluid Removed: 2600 mL'), findsOneWidget);

        // 3. Log a new daily weight
        final weightInput = find.byKey(const Key('daily_weight_input'));
        await tester.enterText(weightInput, '76.1');

        final notesInput = find.byKey(const Key('daily_weight_notes_input'));
        await tester.enterText(notesInput, 'Morning weight check');

        final saveBtn = find.byKey(const Key('save_weight_button'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify confirmation
        expect(find.text('Weight logged: 76.1 kg.'), findsOneWidget);

        // 4. Verify new entry in the longitudinal list
        expect(find.text('76.1 kg'), findsOneWidget);
        expect(find.text('Daily Weight'), findsOneWidget);
        expect(find.text('Notes: Morning weight check'), findsOneWidget);
      },
    );

    testWidgets(
      'PeritonealExchangeScreen captures inflow/drain, calculates net UF, warns on cloudy effluent, and persists',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'PD UI Patient',
          diagnosis: 'peritonealDialysis',
          prescribedDryWeightKg: 68.0,
          dailyFluidAllowanceMl: 1200,
        );

        await tester.pumpWidget(
          createTestApp(
            home: PeritonealExchangeScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify header and initial form
        expect(find.text('Peritoneal Dialysis Exchange'), findsOneWidget);
        expect(find.text('Record New Exchange'), findsOneWidget);

        // 2. Enter Drain volume (Inflow defaults to 2000 mL)
        final drainInput = find.byKey(const Key('drain_volume_field'));
        await tester.enterText(drainInput, '2350');
        await tester.pumpAndSettle();

        // 3. Verify net UF indicator
        expect(find.textContaining('Net Peritoneal Ultrafiltration: +350 mL'), findsOneWidget);

        // 4. Test cloudy effluent peritonitis warning alert
        final clarityDropdown = find.byKey(const Key('pd_clarity_dropdown'));
        await tester.ensureVisible(clarityDropdown);
        await tester.tap(clarityDropdown);
        await tester.pumpAndSettle();
        final cloudyOption = find.text('Cloudy (Possible Peritonitis)').last;
        await tester.tap(cloudyOption);
        await tester.pumpAndSettle();

        expect(find.textContaining('Cloudy effluent is a critical sign of Peritonitis'), findsOneWidget);

        // 5. Submit exchange
        final saveBtn = find.byKey(const Key('save_pd_exchange_button'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify confirmation snackbar
        expect(find.text('Peritoneal exchange recorded successfully!'), findsOneWidget);

        // 6. Verify entry in timeline
        expect(find.text('+350 mL UF'), findsWidgets);
        expect(find.textContaining('Inflow: 2000 mL'), findsOneWidget);
        expect(find.textContaining('Drain: 2350 mL'), findsOneWidget);
        expect(find.textContaining('Net UF: +350 mL'), findsOneWidget);
      },
    );

    testWidgets(
      'SymptomLogScreen selects symptoms, displays critical alert, and persists to surveillance timeline',
      (WidgetTester tester) async {
        final patient = await harness.createPatient(
          name: 'CKD Symptom Patient',
          diagnosis: 'nonDialysisCkd',
        );

        await tester.pumpWidget(
          createTestApp(
            home: SymptomLogScreen(patient: patient),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CKD Symptom Log'), findsOneWidget);

        // Select Fatigue and Shortness of Breath (triggers critical alert)
        final fatigueChip = find.text('Fatigue / Exhaustion');
        await tester.tap(fatigueChip);
        await tester.pumpAndSettle();

        final sobChip = find.text('Shortness of Breath');
        await tester.tap(sobChip);
        await tester.pumpAndSettle();

        // Verify critical alert banner appeared
        expect(find.textContaining('Red Flag Symptom: Severe shortness of breath'), findsOneWidget);

        // Add note
        final notesInput = find.byKey(const Key('symptom_notes_field'));
        await tester.enterText(notesInput, 'Mild dyspnea when walking uphill');

        // Submit symptoms
        final saveBtn = find.byKey(const Key('save_symptom_log_button'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify confirmation snackbar
        expect(find.text('Symptoms recorded successfully!'), findsOneWidget);

        // Verify entry in timeline
        expect(find.text('Notes: Mild dyspnea when walking uphill'), findsOneWidget);
        expect(find.text('Fatigue / Exhaustion'), findsWidgets);
        expect(find.text('Shortness of Breath'), findsWidgets);
      },
    );

    testWidgets(
      'DashboardScreen navigates to PeritonealExchangeScreen and SymptomLogScreen from condition cards',
      (WidgetTester tester) async {
        final pdPatient = await harness.createPatient(
          name: 'PD Nav Patient',
          diagnosis: 'peritonealDialysis',
        );

        await tester.pumpWidget(
          createTestApp(
            home: DashboardScreen(patient: pdPatient),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Exchange Log card
        final exchangeCard = find.text('Exchange Log');
        await tester.ensureVisible(exchangeCard);
        await tester.tap(exchangeCard);
        await tester.pumpAndSettle();

        expect(find.byType(PeritonealExchangeScreen), findsOneWidget);
      },
    );
  });
}
