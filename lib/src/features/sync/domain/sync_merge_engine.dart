import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'patient_sync_bundle.dart';

/// Summary report of records inserted, updated, and skipped during a sync merge.
class SyncMergeResult {
  final int patientsInserted;
  final int patientsUpdated;
  final int dialysisSessionsInserted;
  final int dialysisSessionsUpdated;
  final int bloodPressureLogsInserted;
  final int bloodPressureLogsUpdated;
  final int fluidIntakeLogsInserted;
  final int fluidIntakeLogsUpdated;
  final int fluidOutputLogsInserted;
  final int fluidOutputLogsUpdated;
  final int catheterEventsInserted;
  final int catheterEventsUpdated;
  final int accessInspectionsInserted;
  final int accessInspectionsUpdated;
  final int recordsSkipped;

  const SyncMergeResult({
    this.patientsInserted = 0,
    this.patientsUpdated = 0,
    this.dialysisSessionsInserted = 0,
    this.dialysisSessionsUpdated = 0,
    this.bloodPressureLogsInserted = 0,
    this.bloodPressureLogsUpdated = 0,
    this.fluidIntakeLogsInserted = 0,
    this.fluidIntakeLogsUpdated = 0,
    this.fluidOutputLogsInserted = 0,
    this.fluidOutputLogsUpdated = 0,
    this.catheterEventsInserted = 0,
    this.catheterEventsUpdated = 0,
    this.accessInspectionsInserted = 0,
    this.accessInspectionsUpdated = 0,
    this.recordsSkipped = 0,
  });

  int get totalInserted =>
      patientsInserted +
      dialysisSessionsInserted +
      bloodPressureLogsInserted +
      fluidIntakeLogsInserted +
      fluidOutputLogsInserted +
      catheterEventsInserted +
      accessInspectionsInserted;

  int get totalUpdated =>
      patientsUpdated +
      dialysisSessionsUpdated +
      bloodPressureLogsUpdated +
      fluidIntakeLogsUpdated +
      fluidOutputLogsUpdated +
      catheterEventsUpdated +
      accessInspectionsUpdated;

  int get totalProcessed => totalInserted + totalUpdated + recordsSkipped;
}

/// Deterministic conflict resolution engine that ingests incoming sync bundles
/// into the local Drift SQLite database using UUIDv4 identifiers and updatedAt
/// timestamps (Last-Write-Wins semantics) while guaranteeing foreign key order.
class SyncMergeEngine {
  final AppDatabase database;

  SyncMergeEngine(this.database);

  /// Ingests a [PatientSyncBundle] into the database.
  ///
  /// If [asCaregiverMirror] is true, the ingested patient profile is flagged as
  /// [isCaregiverMirror] = true to represent a replica on a caregiver/clinician device.
  Future<SyncMergeResult> mergeBundle(
    PatientSyncBundle bundle, {
    bool asCaregiverMirror = false,
  }) async {
    int patientsInserted = 0;
    int patientsUpdated = 0;
    int dialysisSessionsInserted = 0;
    int dialysisSessionsUpdated = 0;
    int bloodPressureLogsInserted = 0;
    int bloodPressureLogsUpdated = 0;
    int fluidIntakeLogsInserted = 0;
    int fluidIntakeLogsUpdated = 0;
    int fluidOutputLogsInserted = 0;
    int fluidOutputLogsUpdated = 0;
    int catheterEventsInserted = 0;
    int catheterEventsUpdated = 0;
    int accessInspectionsInserted = 0;
    int accessInspectionsUpdated = 0;
    int recordsSkipped = 0;

    await database.transaction(() async {
      // 1. Merge Patient Profiles (ensures parents exist before foreign key children)
      for (final incomingPatient in bundle.patients) {
        final existingPatient = await (database.select(database.patients)
              ..where((tbl) => tbl.id.equals(incomingPatient.id)))
            .getSingleOrNull();

        if (existingPatient == null) {
          await database.into(database.patients).insert(
                PatientsCompanion.insert(
                  id: Value(incomingPatient.id),
                  name: incomingPatient.name,
                  diagnosis: incomingPatient.diagnosis,
                  prescribedDryWeightKg: Value(incomingPatient.prescribedDryWeightKg),
                  dailyFluidAllowanceMl: Value(incomingPatient.dailyFluidAllowanceMl),
                  vascularAccessType: Value(incomingPatient.vascularAccessType),
                  fistulaArmLocation: Value(incomingPatient.fistulaArmLocation),
                  isCaregiverMirror: Value(asCaregiverMirror ? true : incomingPatient.isCaregiverMirror),
                  createdAt: Value(incomingPatient.createdAt),
                  updatedAt: Value(incomingPatient.updatedAt),
                ),
              );
          patientsInserted++;
        } else {
          if (incomingPatient.updatedAt.isAfter(existingPatient.updatedAt)) {
            await (database.update(database.patients)
                  ..where((tbl) => tbl.id.equals(incomingPatient.id)))
                .write(
              PatientsCompanion(
                name: Value(incomingPatient.name),
                diagnosis: Value(incomingPatient.diagnosis),
                prescribedDryWeightKg: Value(incomingPatient.prescribedDryWeightKg),
                dailyFluidAllowanceMl: Value(incomingPatient.dailyFluidAllowanceMl),
                vascularAccessType: Value(incomingPatient.vascularAccessType),
                fistulaArmLocation: Value(incomingPatient.fistulaArmLocation),
                isCaregiverMirror: Value(asCaregiverMirror ? true : incomingPatient.isCaregiverMirror),
                updatedAt: Value(incomingPatient.updatedAt),
              ),
            );
            patientsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }

      // 2. Merge Dialysis Sessions
      for (final session in bundle.dialysisSessions) {
        final existing = await (database.select(database.dialysisSessions)
              ..where((tbl) => tbl.id.equals(session.id)))
            .getSingleOrNull();

        if (existing == null) {
          await database.into(database.dialysisSessions).insert(
                DialysisSessionsCompanion.insert(
                  id: Value(session.id),
                  patientId: session.patientId,
                  sessionType: session.sessionType,
                  startedAt: session.startedAt,
                  endedAt: Value(session.endedAt),
                  preWeightKg: Value(session.preWeightKg),
                  postWeightKg: Value(session.postWeightKg),
                  calculatedInterdialyticWeightGainKg:
                      Value(session.calculatedInterdialyticWeightGainKg),
                  calculatedUltrafiltrationGoalMl:
                      Value(session.calculatedUltrafiltrationGoalMl),
                  calculatedPostWeightDifferenceKg:
                      Value(session.calculatedPostWeightDifferenceKg),
                  actualFluidRemovedMl: Value(session.actualFluidRemovedMl),
                  notes: Value(session.notes),
                  symptoms: Value(session.symptoms),
                  createdAt: Value(session.createdAt),
                  updatedAt: Value(session.updatedAt),
                ),
              );
          dialysisSessionsInserted++;
        } else {
          if (session.updatedAt.isAfter(existing.updatedAt)) {
            await (database.update(database.dialysisSessions)
                  ..where((tbl) => tbl.id.equals(session.id)))
                .write(
              DialysisSessionsCompanion(
                sessionType: Value(session.sessionType),
                startedAt: Value(session.startedAt),
                endedAt: Value(session.endedAt),
                preWeightKg: Value(session.preWeightKg),
                postWeightKg: Value(session.postWeightKg),
                calculatedInterdialyticWeightGainKg:
                    Value(session.calculatedInterdialyticWeightGainKg),
                calculatedUltrafiltrationGoalMl:
                    Value(session.calculatedUltrafiltrationGoalMl),
                calculatedPostWeightDifferenceKg:
                    Value(session.calculatedPostWeightDifferenceKg),
                actualFluidRemovedMl: Value(session.actualFluidRemovedMl),
                notes: Value(session.notes),
                symptoms: Value(session.symptoms),
                updatedAt: Value(session.updatedAt),
              ),
            );
            dialysisSessionsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }

      // 3. Merge Blood Pressure Logs
      for (final bp in bundle.bloodPressureLogs) {
        final existing = await (database.select(database.bloodPressureLogs)
              ..where((tbl) => tbl.id.equals(bp.id)))
            .getSingleOrNull();

        if (existing == null) {
          await database.into(database.bloodPressureLogs).insert(
                BloodPressureLogsCompanion.insert(
                  id: Value(bp.id),
                  patientId: bp.patientId,
                  systolic: bp.systolic,
                  diastolic: bp.diastolic,
                  pulse: bp.pulse,
                  armUsed: bp.armUsed,
                  isSafeArm: Value(bp.isSafeArm),
                  recordedAt: bp.recordedAt,
                  isPairedAssessment: Value(bp.isPairedAssessment),
                  pairedRole: Value(bp.pairedRole),
                  pairedAssessmentId: Value(bp.pairedAssessmentId),
                  medicationAdministrationId: Value(bp.medicationAdministrationId),
                  elapsedMinutes: Value(bp.elapsedMinutes),
                  systolicDelta: Value(bp.systolicDelta),
                  diastolicDelta: Value(bp.diastolicDelta),
                  pulseDelta: Value(bp.pulseDelta),
                  createdAt: Value(bp.createdAt),
                  updatedAt: Value(bp.updatedAt),
                ),
              );
          bloodPressureLogsInserted++;
        } else {
          if (bp.updatedAt.isAfter(existing.updatedAt)) {
            await (database.update(database.bloodPressureLogs)
                  ..where((tbl) => tbl.id.equals(bp.id)))
                .write(
              BloodPressureLogsCompanion(
                systolic: Value(bp.systolic),
                diastolic: Value(bp.diastolic),
                pulse: Value(bp.pulse),
                armUsed: Value(bp.armUsed),
                isSafeArm: Value(bp.isSafeArm),
                recordedAt: Value(bp.recordedAt),
                isPairedAssessment: Value(bp.isPairedAssessment),
                pairedRole: Value(bp.pairedRole),
                pairedAssessmentId: Value(bp.pairedAssessmentId),
                medicationAdministrationId: Value(bp.medicationAdministrationId),
                elapsedMinutes: Value(bp.elapsedMinutes),
                systolicDelta: Value(bp.systolicDelta),
                diastolicDelta: Value(bp.diastolicDelta),
                pulseDelta: Value(bp.pulseDelta),
                updatedAt: Value(bp.updatedAt),
              ),
            );
            bloodPressureLogsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }

      // 4. Merge Fluid Intake Logs
      for (final intake in bundle.fluidIntakeLogs) {
        final existing = await (database.select(database.fluidIntakeLogs)
              ..where((tbl) => tbl.id.equals(intake.id)))
            .getSingleOrNull();

        if (existing == null) {
          await database.into(database.fluidIntakeLogs).insert(
                FluidIntakeLogsCompanion.insert(
                  id: Value(intake.id),
                  patientId: intake.patientId,
                  volumeMl: intake.volumeMl,
                  beverageType: intake.beverageType,
                  phosphateBinderTaken: Value(intake.phosphateBinderTaken),
                  recordedAt: intake.recordedAt,
                  createdAt: Value(intake.createdAt),
                  updatedAt: Value(intake.updatedAt),
                ),
              );
          fluidIntakeLogsInserted++;
        } else {
          if (intake.updatedAt.isAfter(existing.updatedAt)) {
            await (database.update(database.fluidIntakeLogs)
                  ..where((tbl) => tbl.id.equals(intake.id)))
                .write(
              FluidIntakeLogsCompanion(
                volumeMl: Value(intake.volumeMl),
                beverageType: Value(intake.beverageType),
                phosphateBinderTaken: Value(intake.phosphateBinderTaken),
                recordedAt: Value(intake.recordedAt),
                updatedAt: Value(intake.updatedAt),
              ),
            );
            fluidIntakeLogsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }

      // 5. Merge Fluid Output Logs
      for (final output in bundle.fluidOutputLogs) {
        final existing = await (database.select(database.fluidOutputLogs)
              ..where((tbl) => tbl.id.equals(output.id)))
            .getSingleOrNull();

        if (existing == null) {
          await database.into(database.fluidOutputLogs).insert(
                FluidOutputLogsCompanion.insert(
                  id: Value(output.id),
                  patientId: output.patientId,
                  volumeMl: output.volumeMl,
                  outputType: output.outputType,
                  hematuriaGrade: Value(output.hematuriaGrade),
                  recordedAt: output.recordedAt,
                  createdAt: Value(output.createdAt),
                  updatedAt: Value(output.updatedAt),
                ),
              );
          fluidOutputLogsInserted++;
        } else {
          if (output.updatedAt.isAfter(existing.updatedAt)) {
            await (database.update(database.fluidOutputLogs)
                  ..where((tbl) => tbl.id.equals(output.id)))
                .write(
              FluidOutputLogsCompanion(
                volumeMl: Value(output.volumeMl),
                outputType: Value(output.outputType),
                hematuriaGrade: Value(output.hematuriaGrade),
                recordedAt: Value(output.recordedAt),
                updatedAt: Value(output.updatedAt),
              ),
            );
            fluidOutputLogsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }

      // 6. Merge Catheter Events
      for (final catheter in bundle.catheterEvents) {
        final existing = await (database.select(database.catheterEvents)
              ..where((tbl) => tbl.id.equals(catheter.id)))
            .getSingleOrNull();

        if (existing == null) {
          await database.into(database.catheterEvents).insert(
                CatheterEventsCompanion.insert(
                  id: Value(catheter.id),
                  patientId: catheter.patientId,
                  catheterType: catheter.catheterType,
                  insertionDate: catheter.insertionDate,
                  replacementDueDate: catheter.replacementDueDate,
                  status: catheter.status,
                  notes: Value(catheter.notes),
                  material: Value(catheter.material),
                  lifespanDays: Value(catheter.lifespanDays),
                  bagEmptyingIntervalHours: Value(catheter.bagEmptyingIntervalHours),
                  lastBagEmptiedAt: Value(catheter.lastBagEmptiedAt),
                  createdAt: Value(catheter.createdAt),
                  updatedAt: Value(catheter.updatedAt),
                ),
              );
          catheterEventsInserted++;
        } else {
          if (catheter.updatedAt.isAfter(existing.updatedAt)) {
            await (database.update(database.catheterEvents)
                  ..where((tbl) => tbl.id.equals(catheter.id)))
                .write(
              CatheterEventsCompanion(
                catheterType: Value(catheter.catheterType),
                insertionDate: Value(catheter.insertionDate),
                replacementDueDate: Value(catheter.replacementDueDate),
                status: Value(catheter.status),
                notes: Value(catheter.notes),
                material: Value(catheter.material),
                lifespanDays: Value(catheter.lifespanDays),
                bagEmptyingIntervalHours: Value(catheter.bagEmptyingIntervalHours),
                lastBagEmptiedAt: Value(catheter.lastBagEmptiedAt),
                updatedAt: Value(catheter.updatedAt),
              ),
            );
            catheterEventsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }

      // 7. Merge Access Inspections
      for (final inspection in bundle.accessInspections) {
        final existing = await (database.select(database.accessInspections)
              ..where((tbl) => tbl.id.equals(inspection.id)))
            .getSingleOrNull();

        if (existing == null) {
          await database.into(database.accessInspections).insert(
                AccessInspectionsCompanion.insert(
                  id: Value(inspection.id),
                  patientId: inspection.patientId,
                  accessType: inspection.accessType,
                  anatomicalLocation: inspection.anatomicalLocation,
                  thrillPresent: Value(inspection.thrillPresent),
                  bruitPresent: Value(inspection.bruitPresent),
                  rednessPresent: Value(inspection.rednessPresent),
                  swellingPresent: Value(inspection.swellingPresent),
                  dischargePresent: Value(inspection.dischargePresent),
                  painPresent: Value(inspection.painPresent),
                  notes: Value(inspection.notes),
                  recordedAt: inspection.recordedAt,
                  createdAt: Value(inspection.createdAt),
                  updatedAt: Value(inspection.updatedAt),
                ),
              );
          accessInspectionsInserted++;
        } else {
          if (inspection.updatedAt.isAfter(existing.updatedAt)) {
            await (database.update(database.accessInspections)
                  ..where((tbl) => tbl.id.equals(inspection.id)))
                .write(
              AccessInspectionsCompanion(
                accessType: Value(inspection.accessType),
                anatomicalLocation: Value(inspection.anatomicalLocation),
                thrillPresent: Value(inspection.thrillPresent),
                bruitPresent: Value(inspection.bruitPresent),
                rednessPresent: Value(inspection.rednessPresent),
                swellingPresent: Value(inspection.swellingPresent),
                dischargePresent: Value(inspection.dischargePresent),
                painPresent: Value(inspection.painPresent),
                notes: Value(inspection.notes),
                recordedAt: Value(inspection.recordedAt),
                updatedAt: Value(inspection.updatedAt),
              ),
            );
            accessInspectionsUpdated++;
          } else {
            recordsSkipped++;
          }
        }
      }
    });

    return SyncMergeResult(
      patientsInserted: patientsInserted,
      patientsUpdated: patientsUpdated,
      dialysisSessionsInserted: dialysisSessionsInserted,
      dialysisSessionsUpdated: dialysisSessionsUpdated,
      bloodPressureLogsInserted: bloodPressureLogsInserted,
      bloodPressureLogsUpdated: bloodPressureLogsUpdated,
      fluidIntakeLogsInserted: fluidIntakeLogsInserted,
      fluidIntakeLogsUpdated: fluidIntakeLogsUpdated,
      fluidOutputLogsInserted: fluidOutputLogsInserted,
      fluidOutputLogsUpdated: fluidOutputLogsUpdated,
      catheterEventsInserted: catheterEventsInserted,
      catheterEventsUpdated: catheterEventsUpdated,
      accessInspectionsInserted: accessInspectionsInserted,
      accessInspectionsUpdated: accessInspectionsUpdated,
      recordsSkipped: recordsSkipped,
    );
  }
}
