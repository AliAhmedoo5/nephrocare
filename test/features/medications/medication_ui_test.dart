import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/fluid/presentation/fluid_intake_entry_screen.dart';
import 'package:nephrocare/src/features/medications/presentation/medication_screen.dart';

void main() {
  group('Unified Application & State Seam: Medication UI & 1-Tap Administration', () {
    late NephroTestHarness harness;
    late Patient patient;

    setUp(() async {
      harness = createNephroTestHarness();
      patient = await harness.createPatient(
        name: 'Grace Hopper',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1500,
        prescribedDryWeightKg: 58.0,
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

    testWidgets('MedicationScreen renders active regimens, supports adding a medication, and 1-tap administration', (tester) async {
      // 1. Prescribe initial medication
      final binder = await harness.createMedication(
        patientId: patient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800 mg',
        frequency: 'Three times daily with meals',
        isPhosphateBinder: true,
      );

      await tester.pumpWidget(createTestableWidget(MedicationScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify active regimen card renders
      expect(find.text('Sevelamer Carbonate'), findsOneWidget);
      expect(find.textContaining('800 mg'), findsWidgets);
      expect(find.text('Phosphate Binder'), findsOneWidget);

      // Verify 1-tap administration button exists
      final takeButton = find.byKey(Key('take_medication_${binder.id}'));
      expect(takeButton, findsOneWidget);

      // 1-Tap Take Dose
      await tester.tap(takeButton);
      await tester.pumpAndSettle();

      // Verify administration recorded and surfaces in Today's Administrations
      expect(find.text('Today\'s Administrations'), findsOneWidget);
      expect(find.textContaining('Administered Sevelamer Carbonate'), findsWidgets);

      final administrations = await harness.getMedicationAdministrations(patient.id);
      expect(administrations.length, equals(1));
      expect(administrations.first.medicationId, equals(binder.id));

      // 2. Add new medication via dialog
      await tester.tap(find.byKey(const Key('add_medication_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('med_name_input')), 'Amlodipine');
      await tester.enterText(find.byKey(const Key('med_dosage_input')), '5 mg');
      await tester.enterText(find.byKey(const Key('med_frequency_input')), 'Once daily morning');
      await tester.ensureVisible(find.byKey(const Key('med_is_antihypertensive_checkbox')));
      await tester.tap(find.byKey(const Key('med_is_antihypertensive_checkbox')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('save_medication_button')));
      await tester.tap(find.byKey(const Key('save_medication_button')));
      await tester.pumpAndSettle();

      expect(find.text('Amlodipine'), findsOneWidget);
      expect(find.text('Anti-Hypertensive'), findsOneWidget);

      final activeMeds = await harness.getActiveMedications(patient.id);
      expect(activeMeds.length, equals(2));
    });

    testWidgets('MedicationScreen allows editing and deleting administration records', (tester) async {
      final med = await harness.createMedication(
        patientId: patient.id,
        name: 'Amlodipine',
        dosage: '5 mg',
        frequency: 'Once daily',
        isAntiHypertensive: true,
      );

      final admin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: med.id,
      );

      await tester.pumpWidget(createTestableWidget(MedicationScreen(patient: patient)));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('admin_tile_${admin.id}')), findsOneWidget);

      // Open menu and edit administration
      await tester.tap(find.byKey(Key('admin_menu_${admin.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Record'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('edit_admin_dosage_input')), '10 mg');
      await tester.enterText(find.byKey(const Key('edit_admin_notes_input')), 'Updated dose');
      await tester.tap(find.byKey(const Key('confirm_edit_admin_button')));
      await tester.pumpAndSettle();

      final updatedAdmin = await harness.getMedicationAdministrations(patient.id);
      expect(updatedAdmin.first.dosage, equals('10 mg'));
      expect(updatedAdmin.first.notes, equals('Updated dose'));

      // Open menu and delete administration
      await tester.tap(find.byKey(Key('admin_menu_${admin.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Record'));
      await tester.pumpAndSettle();

      // Confirm deletion in dialog
      await tester.tap(find.byKey(const Key('confirm_delete_admin_button')));
      await tester.pumpAndSettle();

      final postDelete = await harness.getMedicationAdministrations(patient.id);
      expect(postDelete, isEmpty);
    });

    testWidgets('DashboardScreen renders 1-tap administration for active medications and records dose', (tester) async {
      final med = await harness.createMedication(
        patientId: patient.id,
        name: 'Carvedilol',
        dosage: '6.25 mg',
        frequency: 'Twice daily',
        isAntiHypertensive: true,
      );

      await tester.pumpWidget(createTestableWidget(DashboardScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify quick administration tile exists on dashboard
      final quickTakeButton = find.byKey(Key('dashboard_quick_take_${med.id}'));
      expect(quickTakeButton, findsOneWidget);

      // Tap 1-tap take button directly from dashboard
      await tester.tap(quickTakeButton);
      await tester.pumpAndSettle();

      // Verify administration is persisted in repository
      final admins = await harness.getMedicationAdministrations(patient.id);
      expect(admins.length, equals(1));
      expect(admins.first.medicationName, equals('Carvedilol'));
      expect(admins.first.dosage, equals('6.25 mg'));
      expect(admins.first.isAntiHypertensive, isTrue);
    });

    testWidgets('FluidIntakeEntryScreen prompts for Phosphate Binder and synchronizes administration', (tester) async {
      final binder = await harness.createMedication(
        patientId: patient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800 mg',
        frequency: 'With meals',
        isPhosphateBinder: true,
      );

      await tester.pumpWidget(createTestableWidget(FluidIntakeEntryScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify binder prompt highlights active binder prescription
      expect(find.textContaining('Sevelamer Carbonate'), findsWidgets);
      expect(find.byKey(const Key('phosphate_binder_toggle')), findsOneWidget);

      // Enter volume and check binder taken
      await tester.enterText(find.byKey(const Key('volume_input')), '300');
      await tester.ensureVisible(find.byKey(const Key('phosphate_binder_toggle')));
      await tester.tap(find.byKey(const Key('phosphate_binder_toggle')));
      await tester.pumpAndSettle();

      // Save fluid intake
      await tester.ensureVisible(find.byKey(const Key('save_fluid_intake_button')));
      await tester.tap(find.byKey(const Key('save_fluid_intake_button')));
      await tester.pumpAndSettle();

      // Verify fluid intake was saved
      final intakeLogs = await harness.getFluidIntakeLogs(patient.id);
      expect(intakeLogs.length, equals(1));
      expect(intakeLogs.first.phosphateBinderTaken, isTrue);

      // Verify medication administration was synchronized
      final admins = await harness.getMedicationAdministrations(patient.id);
      expect(admins.length, equals(1));
      expect(admins.first.medicationId, equals(binder.id));
      expect(admins.first.isPhosphateBinder, isTrue);
    });
  });
}
