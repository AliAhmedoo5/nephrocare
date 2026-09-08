import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nephrocare/main.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
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
          vascularAccessType: VascularAccessType.dialysisCentralLine.name,
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
        expect(find.text('Blood Pressure'), findsOneWidget);

        // Tap the Blood Pressure card
        await tester.tap(find.text('Blood Pressure'));
        await tester.pumpAndSettle();

        // Should navigate to BloodPressureEntryScreen
        expect(find.byKey(const Key('fistula_arm_safety_banner')), findsOneWidget);
        expect(find.byKey(const Key('save_bp_button')), findsOneWidget);
      },
    );
  });
}
