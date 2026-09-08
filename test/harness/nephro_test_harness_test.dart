import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/domain/vascular_safety_rules.dart';

void main() {
  group('Unified Application & State Harness Seam', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Initializes in-memory Drift database and registers patient via clinical harness helper', () async {
      final patient = await harness.createPatient(
        name: 'John Doe',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 70.5,
        dailyFluidAllowanceMl: 1500,
        fistulaArmLocation: 'leftArm',
      );

      expect(patient.id, isNotEmpty);
      expect(patient.name, equals('John Doe'));
      expect(patient.diagnosis, equals('hemodialysis'));
      expect(patient.prescribedDryWeightKg, equals(70.5));
      expect(patient.dailyFluidAllowanceMl, equals(1500));
      expect(patient.fistulaArmLocation, equals('leftArm'));
      expect(patient.createdAt, isNotNull);
      expect(patient.updatedAt, isNotNull);
    });

    test('All 7 clinical core entity tables are exercised via high-level harness seam', () async {
      final now = DateTime.now().toUtc();

      // 1. Register Patient with Fistula Arm Safety metadata
      final patient = await harness.createPatient(
        name: 'Jane Smith',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 65.0,
        fistulaArmLocation: 'leftArm',
      );
      expect(patient.id, isNotEmpty);

      // 2. Record Dialysis Session
      final session = await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now,
        preWeightKg: 67.2,
        postWeightKg: 65.1,
        calculatedInterdialyticWeightGainKg: 2.2,
        calculatedUltrafiltrationGoalMl: 2200,
        actualFluidRemovedMl: 2100,
      );
      expect(session.id, isNotEmpty);
      expect(session.calculatedUltrafiltrationGoalMl, equals(2200));

      // 3. Record Blood Pressure Log
      final bp = await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 124,
        diastolic: 82,
        pulse: 74,
        armUsed: 'rightArm',
        isSafeArm: true,
        recordedAt: now,
      );
      expect(bp.id, isNotEmpty);
      expect(bp.armUsed, equals('rightArm'));
      expect(bp.isSafeArm, isTrue);

      // 4. Record Fluid Intake with Phosphate Binder prompt
      final intake = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 250,
        beverageType: 'Water',
        phosphateBinderTaken: true,
        recordedAt: now,
      );
      expect(intake.id, isNotEmpty);
      expect(intake.phosphateBinderTaken, isTrue);

      // 5. Record Fluid Output with Hematuria Grade
      final output = await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 300,
        outputType: 'urine',
        hematuriaGrade: 1, // Clear per CONTEXT.md
        recordedAt: now,
      );
      expect(output.id, isNotEmpty);
      expect(output.hematuriaGrade, equals(1));

      // 6. Record Catheter Event with 14-day replacement advisory window
      final catheter = await harness.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: now,
        replacementDueDate: now.add(const Duration(days: 14)),
        status: 'active',
      );
      expect(catheter.id, isNotEmpty);
      expect(catheter.status, equals('active'));

      // 7. Record Vascular Access Inspection
      final inspection = await harness.recordAccessInspection(
        patientId: patient.id,
        accessType: 'arteriovenousFistula',
        anatomicalLocation: 'leftArm',
        thrillPresent: true,
        bruitPresent: true,
        recordedAt: now,
      );
      expect(inspection.id, isNotEmpty);
      expect(inspection.thrillPresent, isTrue);
      expect(inspection.bruitPresent, isTrue);

      // Verify all records exist in in-memory database
      final db = harness.database;
      final patientCount = (await db.select(db.patients).get()).length;
      final sessionCount = (await db.select(db.dialysisSessions).get()).length;
      final bpCount = (await db.select(db.bloodPressureLogs).get()).length;
      final intakeCount = (await db.select(db.fluidIntakeLogs).get()).length;
      final outputCount = (await db.select(db.fluidOutputLogs).get()).length;
      final catheterCount = (await db.select(db.catheterEvents).get()).length;
      final inspectionCount = (await db.select(db.accessInspections).get()).length;

      expect(patientCount, equals(1));
      expect(sessionCount, equals(1));
      expect(bpCount, equals(1));
      expect(intakeCount, equals(1));
      expect(outputCount, equals(1));
      expect(catheterCount, equals(1));
      expect(inspectionCount, equals(1));
    });

    test('Top-level test harness verifies that arm selection lockout is strictly enforced and safe arm readings persist and surface in hemodynamic trends', () async {
      final now = DateTime.now().toUtc();

      // 1. Create Patient with Arteriovenous Fistula on Right Arm
      final patient = await harness.createPatient(
        name: 'Carlos Rivera',
        diagnosis: 'hemodialysis',
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'rightArm',
      );

      // 2. Verify arm lockout enforcement: attempting to record on right arm throws FistulaArmSafetyException
      expect(
        () => harness.recordBloodPressure(
          patientId: patient.id,
          systolic: 140,
          diastolic: 90,
          pulse: 80,
          armUsed: 'rightArm',
          recordedAt: now,
        ),
        throwsA(isA<FistulaArmSafetyException>()),
      );

      // 3. Record on safe arm (leftArm)
      final record1 = await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 132,
        diastolic: 84,
        pulse: 76,
        armUsed: 'leftArm',
        recordedAt: now.subtract(const Duration(minutes: 30)),
      );
      expect(record1.id, isNotEmpty);
      expect(record1.isSafeArm, isTrue);

      final record2 = await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 128,
        diastolic: 80,
        pulse: 72,
        armUsed: 'leftArm',
        recordedAt: now,
      );
      expect(record2.id, isNotEmpty);
      expect(record2.isSafeArm, isTrue);

      // 4. Verify safe arm readings persist and surface in hemodynamic trends
      final trends = await harness.getHemodynamicTrends(patient.id);
      expect(trends.length, equals(2));
      expect(trends.first.id, equals(record2.id));
      expect(trends.first.systolic, equals(128));
      expect(trends.first.armUsed, equals('leftArm'));
      expect(trends.last.id, equals(record1.id));
      expect(trends.last.systolic, equals(132));
      expect(trends.last.armUsed, equals('leftArm'));
    });
  });
}
