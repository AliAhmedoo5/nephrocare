import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/sync/domain/patient_sync_bundle.dart';
import 'package:nephrocare/src/features/sync/domain/sync_merge_engine.dart';

void main() {
  group('Deterministic Conflict Resolution & Database Merging Engine Seam', () {
    late NephroTestHarness harness;
    late SyncMergeEngine mergeEngine;

    setUp(() {
      harness = createNephroTestHarness();
      mergeEngine = SyncMergeEngine(harness.database);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Serializes and deserializes PatientSyncBundle cleanly via JSON', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final patient = await harness.createPatient(
        name: 'Alice Springs',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 65.0,
        dailyFluidAllowanceMl: 1000,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        createdAt: t0,
        updatedAt: t0,
      );

      final session = await harness.recordPreDialysisCheckIn(
        patientId: patient.id,
        startedAt: t0,
        preWeightKg: 67.5,
        notes: 'In-progress hemodialysis session',
      );

      final med = await harness.createMedication(
        patientId: patient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800mg',
        frequency: 'TID with meals',
        isPhosphateBinder: true,
        createdAt: t0,
        updatedAt: t0,
      );

      final admin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: med.id,
        medicationName: med.name,
        dosage: med.dosage,
        administeredAt: t0,
      );

      final bp = await harness.recordBaselineBloodPressure(
        patientId: patient.id,
        medicationAdministrationId: admin.id,
        medicationName: med.name,
        systolic: 155,
        diastolic: 95,
        pulse: 78,
        armUsed: 'rightArm',
        recordedAt: t0,
      );

      final intake = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 250,
        beverageType: 'Water',
        recordedAt: t0,
      );

      final output = await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 300,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: t0,
      );

      final catheter = await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: t0,
        replacementDueDate: t0.add(const Duration(days: 30)),
        status: 'active',
        material: 'silicone30Day',
        lifespanDays: 30,
        bagEmptyingIntervalHours: 8,
        lastBagEmptiedAt: t0,
      );

      final inspection = await harness.recordAccessInspection(
        patientId: patient.id,
        accessType: 'arteriovenousFistula',
        anatomicalLocation: 'leftArm',
        thrillPresent: true,
        bruitPresent: true,
        recordedAt: t0,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: harness.database,
        patientId: patient.id,
      );

      expect(bundle.patient.id, equals(patient.id));
      expect(bundle.dialysisSessions.length, equals(1));
      expect(bundle.dialysisSessions.first.status, equals('inProgress'));
      expect(bundle.medications.length, equals(1));
      expect(bundle.medications.first.id, equals(med.id));
      expect(bundle.medicationAdministrations.length, equals(1));
      expect(bundle.medicationAdministrations.first.id, equals(admin.id));
      expect(bundle.bloodPressureLogs.length, equals(1));
      expect(bundle.bloodPressureLogs.first.isPairedAssessment, isTrue);
      expect(bundle.bloodPressureLogs.first.pairedRole, equals('baseline'));
      expect(bundle.catheterEvents.first.material, equals('silicone30Day'));
      expect(bundle.catheterEvents.first.bagEmptyingIntervalHours, equals(8));
      expect(bundle.fluidIntakeLogs.length, equals(1));
      expect(bundle.fluidOutputLogs.length, equals(1));
      expect(bundle.catheterEvents.length, equals(1));
      expect(bundle.accessInspections.length, equals(1));

      // JSON roundtrip
      final jsonString = jsonEncode(bundle.toJson());
      final decoded = PatientSyncBundle.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(decoded.patient.id, equals(patient.id));
      expect(decoded.patient.name, equals('Alice Springs'));
      expect(decoded.dialysisSessions.first.id, equals(session.id));
      expect(decoded.dialysisSessions.first.status, equals('inProgress'));
      expect(decoded.medications.first.id, equals(med.id));
      expect(decoded.medications.first.name, equals('Sevelamer Carbonate'));
      expect(decoded.medications.first.isPhosphateBinder, isTrue);
      expect(decoded.medicationAdministrations.first.id, equals(admin.id));
      expect(decoded.medicationAdministrations.first.medicationId, equals(med.id));
      expect(decoded.bloodPressureLogs.first.id, equals(bp.id));
      expect(decoded.bloodPressureLogs.first.isPairedAssessment, isTrue);
      expect(decoded.bloodPressureLogs.first.pairedRole, equals('baseline'));
      expect(decoded.catheterEvents.first.id, equals(catheter.id));
      expect(decoded.catheterEvents.first.material, equals('silicone30Day'));
      expect(decoded.catheterEvents.first.bagEmptyingIntervalHours, equals(8));
      expect(decoded.fluidIntakeLogs.first.id, equals(intake.id));
      expect(decoded.fluidOutputLogs.first.id, equals(output.id));
      expect(decoded.accessInspections.first.id, equals(inspection.id));
    });

    test('Ingests fresh patient bundle into clean database with foreign key relational integrity', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final sourceHarness = createNephroTestHarness();
      addTearDown(() => sourceHarness.dispose());

      final patient = await sourceHarness.createPatient(
        name: 'Bob Miller',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 72.0,
        dailyFluidAllowanceMl: 1200,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        createdAt: t0,
        updatedAt: t0,
      );

      await sourceHarness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        preWeightKg: 74.0,
      );

      await sourceHarness.recordBloodPressure(
        patientId: patient.id,
        systolic: 130,
        diastolic: 80,
        pulse: 72,
        armUsed: 'rightArm',
        recordedAt: t0,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: sourceHarness.database,
        patientId: patient.id,
      );

      // Merge into target (empty) database
      final result = await mergeEngine.mergeBundle(bundle, asCaregiverMirror: true);

      expect(result.patientsInserted, equals(1));
      expect(result.dialysisSessionsInserted, equals(1));
      expect(result.bloodPressureLogsInserted, equals(1));

      final importedPatient = await harness.getPatient(patient.id);
      expect(importedPatient, isNotNull);
      expect(importedPatient!.name, equals('Bob Miller'));
      expect(importedPatient.isCaregiverMirror, isTrue);

      final importedSessions = await harness.getDialysisSessions(patient.id);
      expect(importedSessions.length, equals(1));
      expect(importedSessions.first.patientId, equals(patient.id));
    });

    test('Deterministic Last-Write-Wins: updates record when incoming updatedAt is newer', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final t1 = DateTime.utc(2026, 3, 2, 10, 0);

      // Local database has patient updated at t0
      await harness.createPatient(
        id: 'patient-uuid-1',
        name: 'Charlie Old Name',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 70.0,
        createdAt: t0,
        updatedAt: t0,
      );

      final sourceHarness = createNephroTestHarness();
      addTearDown(() => sourceHarness.dispose());

      // Remote database has same patient with newer updatedAt t1
      await sourceHarness.createPatient(
        id: 'patient-uuid-1',
        name: 'Charlie New Name',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 70.5,
        createdAt: t0,
        updatedAt: t1,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: sourceHarness.database,
        patientId: 'patient-uuid-1',
      );

      final result = await mergeEngine.mergeBundle(bundle);

      expect(result.patientsUpdated, equals(1));
      expect(result.patientsInserted, equals(0));

      final merged = await harness.getPatient('patient-uuid-1');
      expect(merged!.name, equals('Charlie New Name'));
      expect(merged.prescribedDryWeightKg, equals(70.5));
      expect(merged.updatedAt.toUtc(), equals(t1.toUtc()));
    });

    test('Deterministic Last-Write-Wins: preserves local record when incoming updatedAt is older or equal', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final t1 = DateTime.utc(2026, 3, 2, 10, 0);

      // Local database has patient updated at t1
      await harness.createPatient(
        id: 'patient-uuid-2',
        name: 'David Current Local',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 80.0,
        createdAt: t0,
        updatedAt: t1,
      );

      final sourceHarness = createNephroTestHarness();
      addTearDown(() => sourceHarness.dispose());

      // Remote database has stale patient updated at t0
      await sourceHarness.createPatient(
        id: 'patient-uuid-2',
        name: 'David Stale Remote',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 78.0,
        createdAt: t0,
        updatedAt: t0,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: sourceHarness.database,
        patientId: 'patient-uuid-2',
      );

      final result = await mergeEngine.mergeBundle(bundle);

      expect(result.patientsUpdated, equals(0));
      expect(result.recordsSkipped, greaterThan(0));

      final merged = await harness.getPatient('patient-uuid-2');
      expect(merged!.name, equals('David Current Local'));
      expect(merged.prescribedDryWeightKg, equals(80.0));
    });

    test('Deterministic Last-Write-Wins: merges medications and medication administrations in foreign-key order', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final t1 = DateTime.utc(2026, 3, 2, 10, 0);

      // Local database has medication updated at t0
      final patient = await harness.createPatient(
        id: 'patient-med-1',
        name: 'Eve Med Test',
        diagnosis: 'hemodialysis',
        createdAt: t0,
        updatedAt: t0,
      );

      await harness.createMedication(
        id: 'med-uuid-1',
        patientId: patient.id,
        name: 'Amlodipine',
        dosage: '5mg',
        frequency: 'Daily',
        isAntiHypertensive: true,
        createdAt: t0,
        updatedAt: t0,
      );

      final sourceHarness = createNephroTestHarness();
      addTearDown(() => sourceHarness.dispose());

      await sourceHarness.createPatient(
        id: 'patient-med-1',
        name: 'Eve Med Test',
        diagnosis: 'hemodialysis',
        createdAt: t0,
        updatedAt: t0,
      );

      // Newer medication definition on remote
      await sourceHarness.createMedication(
        id: 'med-uuid-1',
        patientId: patient.id,
        name: 'Amlodipine Besylate',
        dosage: '10mg',
        frequency: 'Daily in morning',
        isAntiHypertensive: true,
        createdAt: t0,
        updatedAt: t1,
      );

      // New administration on remote referencing med-uuid-1
      await sourceHarness.recordMedicationAdministration(
        id: 'admin-uuid-1',
        patientId: patient.id,
        medicationId: 'med-uuid-1',
        medicationName: 'Amlodipine Besylate',
        dosage: '10mg',
        administeredAt: t1,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: sourceHarness.database,
        patientId: patient.id,
      );

      final result = await mergeEngine.mergeBundle(bundle);

      expect(result.medicationsUpdated, equals(1));
      expect(result.medicationAdministrationsInserted, equals(1));

      final updatedMed = (await harness.getAllMedications(patient.id))
          .firstWhere((m) => m.id == 'med-uuid-1');
      expect(updatedMed.name, equals('Amlodipine Besylate'));
      expect(updatedMed.dosage, equals('10mg'));

      final admins = await harness.getMedicationAdministrations(patient.id);
      expect(admins.length, equals(1));
      expect(admins.first.id, equals('admin-uuid-1'));
      expect(admins.first.medicationId, equals('med-uuid-1'));
    });

    test('Deterministic Last-Write-Wins: updates continuous hemodialysis session status and catheter configurations', () async {
      final t0 = DateTime.utc(2026, 3, 1, 8, 0);
      final t1 = DateTime.utc(2026, 3, 1, 12, 0);

      final patient = await harness.createPatient(
        id: 'patient-session-1',
        name: 'Frank Session Test',
        diagnosis: 'hemodialysis',
        createdAt: t0,
        updatedAt: t0,
      );

      // Local has in-progress session and catheter
      await harness.recordDialysisSession(
        id: 'session-uuid-1',
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        preWeightKg: 70.0,
        status: 'inProgress',
        createdAt: t0,
        updatedAt: t0,
      );

      await harness.recordCatheterEvent(
        id: 'catheter-uuid-1',
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: t0,
        replacementDueDate: t0.add(const Duration(days: 14)),
        status: 'active',
        material: 'latex14Day',
        lifespanDays: 14,
        bagEmptyingIntervalHours: 8,
        lastBagEmptiedAt: t0,
        createdAt: t0,
        updatedAt: t0,
      );

      final sourceHarness = createNephroTestHarness();
      addTearDown(() => sourceHarness.dispose());

      await sourceHarness.createPatient(
        id: 'patient-session-1',
        name: 'Frank Session Test',
        diagnosis: 'hemodialysis',
        createdAt: t0,
        updatedAt: t0,
      );

      // Remote completed the session and updated catheter
      await sourceHarness.recordDialysisSession(
        id: 'session-uuid-1',
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        endedAt: t1,
        preWeightKg: 70.0,
        postWeightKg: 68.0,
        actualFluidRemovedMl: 2000,
        notes: 'Session finished cleanly',
        status: 'completed',
        createdAt: t0,
        updatedAt: t1,
      );

      await sourceHarness.recordCatheterEvent(
        id: 'catheter-uuid-1',
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: t0,
        replacementDueDate: t0.add(const Duration(days: 30)),
        status: 'active',
        material: 'silicone30Day',
        lifespanDays: 30,
        bagEmptyingIntervalHours: 6,
        lastBagEmptiedAt: t1,
        createdAt: t0,
        updatedAt: t1,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: sourceHarness.database,
        patientId: patient.id,
      );

      final result = await mergeEngine.mergeBundle(bundle);

      expect(result.dialysisSessionsUpdated, equals(1));
      expect(result.catheterEventsUpdated, equals(1));

      final sessions = await harness.getDialysisSessions(patient.id);
      expect(sessions.first.status, equals('completed'));
      expect(sessions.first.postWeightKg, equals(68.0));

      final activeCatheter = await harness.getActiveCatheter(patient.id);
      expect(activeCatheter!.material, equals('silicone30Day'));
      expect(activeCatheter.lifespanDays, equals(30));
      expect(activeCatheter.bagEmptyingIntervalHours, equals(6));
    });
  });
}
