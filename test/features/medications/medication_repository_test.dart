import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/medications/data/medication_repository.dart';

void main() {
  group('Unified Application & State Seam: Medication Repository & Adherence Seam', () {
    late NephroTestHarness harness;
    late MedicationRepository medRepo;
    late Patient testPatient;

    setUp(() async {
      harness = createNephroTestHarness();
      medRepo = MedicationRepository(harness.database);
      testPatient = await harness.createPatient(
        name: 'Eleanor Vance',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1200,
        prescribedDryWeightKg: 60.0,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('createMedication persists prescribed regimen with clinical classifications', () async {
      final med = await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800 mg',
        frequency: 'Three times daily with meals',
        instructions: 'Take during or immediately after meals to bind phosphorus',
        isPhosphateBinder: true,
        isAntiHypertensive: false,
        isActive: true,
      );

      expect(med.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(med.id),
        isTrue,
      );
      expect(med.patientId, equals(testPatient.id));
      expect(med.name, equals('Sevelamer Carbonate'));
      expect(med.dosage, equals('800 mg'));
      expect(med.frequency, equals('Three times daily with meals'));
      expect(med.instructions, equals('Take during or immediately after meals to bind phosphorus'));
      expect(med.isPhosphateBinder, isTrue);
      expect(med.isAntiHypertensive, isFalse);
      expect(med.isActive, isTrue);
    });

    test('getActiveMedications and watchActiveMedications filter by patient and active status', () async {
      final med1 = await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Amlodipine',
        dosage: '5 mg',
        frequency: 'Once daily morning',
        isAntiHypertensive: true,
        isActive: true,
      );
      await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Discontinued Drug',
        dosage: '10 mg',
        frequency: 'As needed',
        isActive: false,
      );

      final activeMeds = await medRepo.getActiveMedications(testPatient.id);
      expect(activeMeds.length, equals(1));
      expect(activeMeds.first.id, equals(med1.id));
      expect(activeMeds.first.isAntiHypertensive, isTrue);

      final streamList = await medRepo.watchActiveMedications(testPatient.id).first;
      expect(streamList.length, equals(1));
      expect(streamList.first.name, equals('Amlodipine'));
    });

    test('hasActivePhosphateBinders and getActivePhosphateBinders identify prescribed binders', () async {
      expect(await medRepo.hasActivePhosphateBinders(testPatient.id), isFalse);
      expect(await medRepo.getActivePhosphateBinders(testPatient.id), isEmpty);

      final binder = await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Calcium Acetate',
        dosage: '667 mg',
        frequency: '2 capsules with meals',
        isPhosphateBinder: true,
        isActive: true,
      );

      expect(await medRepo.hasActivePhosphateBinders(testPatient.id), isTrue);
      final binders = await medRepo.getActivePhosphateBinders(testPatient.id);
      expect(binders.length, equals(1));
      expect(binders.first.id, equals(binder.id));
    });

    test('updateMedication modifies prescription details and status', () async {
      final med = await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Losartan',
        dosage: '50 mg',
        frequency: 'Once daily',
        isAntiHypertensive: true,
      );

      final updated = await medRepo.updateMedication(
        id: med.id,
        dosage: '100 mg',
        instructions: 'Increased dosage per nephrologist',
        isActive: false,
      );

      expect(updated.dosage, equals('100 mg'));
      expect(updated.instructions, equals('Increased dosage per nephrologist'));
      expect(updated.isActive, isFalse);

      final active = await medRepo.getActiveMedications(testPatient.id);
      expect(active.any((m) => m.id == med.id), isFalse);
    });

    test('recordAdministration records 1-tap administration with single tap defaults', () async {
      final med = await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800 mg',
        frequency: 'Three times daily with meals',
        isPhosphateBinder: true,
      );

      final now = DateTime.now().toUtc();
      final admin = await medRepo.recordAdministration(
        patientId: testPatient.id,
        medicationId: med.id,
        administeredAt: now,
      );

      expect(admin.id, isNotEmpty);
      expect(admin.patientId, equals(testPatient.id));
      expect(admin.medicationId, equals(med.id));
      expect(admin.medicationName, equals('Sevelamer Carbonate'));
      expect(admin.dosage, equals('800 mg'));
      expect(admin.isPhosphateBinder, isTrue);
      expect(admin.isAntiHypertensive, isFalse);

      final admins = await medRepo.getAdministrations(testPatient.id);
      expect(admins.length, equals(1));
      expect(admins.first.id, equals(admin.id));
    });

    test('updateAdministration and deleteAdministration allow correcting accidental entries', () async {
      final med = await medRepo.createMedication(
        patientId: testPatient.id,
        name: 'Metoprolol',
        dosage: '25 mg',
        frequency: 'Twice daily',
        isAntiHypertensive: true,
      );

      final admin = await medRepo.recordAdministration(
        patientId: testPatient.id,
        medicationId: med.id,
        dosage: '25 mg',
      );

      // Edit administration
      final updatedAdmin = await medRepo.updateAdministration(
        id: admin.id,
        dosage: '50 mg',
        notes: 'Corrected dosage taken',
      );
      expect(updatedAdmin.dosage, equals('50 mg'));
      expect(updatedAdmin.notes, equals('Corrected dosage taken'));

      // Delete administration
      final deleteCount = await medRepo.deleteAdministration(admin.id);
      expect(deleteCount, equals(1));

      final emptyAdmins = await medRepo.getAdministrations(testPatient.id);
      expect(emptyAdmins, isEmpty);
    });
  });
}
