import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_check_in_screen.dart';
import 'package:nephrocare/src/features/dialysis/presentation/hemodialysis_post_session_screen.dart';
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
  });
}
