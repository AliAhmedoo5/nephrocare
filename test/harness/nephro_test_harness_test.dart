import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/core/database/app_database.dart';

void main() {
  group('Unified Application & State Harness Seam', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Initializes in-memory Drift database with Riverpod provider and compiles type-safely', () async {
      final db = harness.database;
      expect(db, isNotNull);

      // Verify patients table accepts UUIDv4 entity and timestamps
      final patientId = harness.generateUuid();
      final now = DateTime.now().toUtc();

      await db.into(db.patients).insert(
        PatientsCompanion.insert(
          id: patientId,
          name: 'John Doe',
          diagnosis: 'hemodialysis',
          prescribedDryWeightKg: const drift.Value(70.5),
          dailyFluidAllowanceMl: const drift.Value(1500),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final patient = await (db.select(db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingle();
      expect(patient.id, equals(patientId));
      expect(patient.name, equals('John Doe'));
      expect(patient.diagnosis, equals('hemodialysis'));
      expect(patient.prescribedDryWeightKg, equals(70.5));
      expect(patient.dailyFluidAllowanceMl, equals(1500));
      expect(patient.updatedAt, isNotNull);
    });

    test('All 7 clinical core entity tables are defined with UUID primary keys and updated_at timestamps', () async {
      final db = harness.database;
      final now = DateTime.now().toUtc();
      final patientId = harness.generateUuid();

      // 1. Patient
      await db.into(db.patients).insert(
        PatientsCompanion.insert(
          id: patientId,
          name: 'Jane Smith',
          diagnosis: 'hemodialysis',
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 2. Dialysis Session
      final sessionId = harness.generateUuid();
      await db.into(db.dialysisSessions).insert(
        DialysisSessionsCompanion.insert(
          id: sessionId,
          patientId: patientId,
          sessionType: 'hemodialysis',
          startedAt: now,
          preWeightKg: const drift.Value(72.5),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 3. Blood Pressure Log
      final bpId = harness.generateUuid();
      await db.into(db.bloodPressureLogs).insert(
        BloodPressureLogsCompanion.insert(
          id: bpId,
          patientId: patientId,
          systolic: 120,
          diastolic: 80,
          pulse: 72,
          armUsed: 'rightArm',
          isSafeArm: const drift.Value(true),
          recordedAt: now,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 4. Fluid Intake Log
      final intakeId = harness.generateUuid();
      await db.into(db.fluidIntakeLogs).insert(
        FluidIntakeLogsCompanion.insert(
          id: intakeId,
          patientId: patientId,
          volumeMl: 250,
          beverageType: 'Water',
          phosphateBinderTaken: const drift.Value(true),
          recordedAt: now,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 5. Fluid Output Log
      final outputId = harness.generateUuid();
      await db.into(db.fluidOutputLogs).insert(
        FluidOutputLogsCompanion.insert(
          id: outputId,
          patientId: patientId,
          volumeMl: 300,
          outputType: 'urine',
          hematuriaGrade: const drift.Value(1),
          recordedAt: now,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 6. Catheter Event
      final catheterId = harness.generateUuid();
      await db.into(db.catheterEvents).insert(
        CatheterEventsCompanion.insert(
          id: catheterId,
          patientId: patientId,
          catheterType: 'foley',
          insertionDate: now,
          replacementDueDate: now.add(const Duration(days: 14)),
          status: 'active',
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 7. Access Inspection
      final accessId = harness.generateUuid();
      await db.into(db.accessInspections).insert(
        AccessInspectionsCompanion.insert(
          id: accessId,
          patientId: patientId,
          accessType: 'arteriovenousFistula',
          anatomicalLocation: 'leftArm',
          thrillPresent: const drift.Value(true),
          bruitPresent: const drift.Value(true),
          recordedAt: now,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Verify all tables hold their records
      final sessions = await db.select(db.dialysisSessions).get();
      final bps = await db.select(db.bloodPressureLogs).get();
      final intakes = await db.select(db.fluidIntakeLogs).get();
      final outputs = await db.select(db.fluidOutputLogs).get();
      final catheters = await db.select(db.catheterEvents).get();
      final inspections = await db.select(db.accessInspections).get();

      expect(sessions.length, equals(1));
      expect(bps.length, equals(1));
      expect(intakes.length, equals(1));
      expect(outputs.length, equals(1));
      expect(catheters.length, equals(1));
      expect(inspections.length, equals(1));
    });
  });
}
