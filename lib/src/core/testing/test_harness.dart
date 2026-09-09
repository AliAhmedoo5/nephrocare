import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../features/blood_pressure/data/blood_pressure_repository.dart';
import '../../features/catheter/data/catheter_repository.dart';
import '../../features/catheter/domain/catheter_lifespan_rules.dart';
import '../../features/dialysis/data/dialysis_session_repository.dart';
import '../../features/fluid/data/fluid_repository.dart';
import '../../features/fluid/domain/fluid_balance_summary.dart';
import '../../features/medications/data/medication_repository.dart';
import '../../features/profile/data/patient_repository.dart';
import '../../features/reports/data/clinical_report_repository.dart';
import '../../features/reports/domain/clinical_report_config.dart';
import '../../features/reports/domain/clinical_report_data.dart';
import '../../features/reports/domain/clinical_report_pdf_generator.dart';
import '../../features/sync/domain/patient_sync_bundle.dart';
import '../../features/sync/domain/sync_merge_engine.dart';

/// Test harness establishing the Unified Application & State Seam.
///
/// Binds an in-memory Drift SQLite database to a Riverpod [ProviderContainer],
/// providing high-level helper methods to exercise clinical workflows
/// without reaching into database internals or requiring emulator overhead.
class NephroTestHarness {
  final ProviderContainer container;
  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  NephroTestHarness({
    required this.container,
    required this.database,
  });

  /// Generates a RFC 4122 compliant UUIDv4 identifier.
  String generateUuid() => _uuid.v4();

  /// Clinical helper to register a new Patient profile.
  Future<Patient> createPatient({
    String? id,
    required String name,
    required String diagnosis,
    double? prescribedDryWeightKg,
    int? dailyFluidAllowanceMl,
    String? vascularAccessType,
    String? fistulaArmLocation,
    bool isCaregiverMirror = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final patientId = id ?? generateUuid();
    final now = DateTime.now().toUtc();
    final created = createdAt?.toUtc() ?? now;
    final updated = updatedAt?.toUtc() ?? created;

    final companion = PatientsCompanion.insert(
      id: drift.Value(patientId),
      name: name,
      diagnosis: diagnosis,
      prescribedDryWeightKg: drift.Value(prescribedDryWeightKg),
      dailyFluidAllowanceMl: drift.Value(dailyFluidAllowanceMl),
      vascularAccessType: drift.Value(vascularAccessType),
      fistulaArmLocation: drift.Value(fistulaArmLocation),
      isCaregiverMirror: drift.Value(isCaregiverMirror),
      createdAt: drift.Value(created),
      updatedAt: drift.Value(updated),
    );
    await database.into(database.patients).insert(companion);
    return (database.select(database.patients)..where((tbl) => tbl.id.equals(patientId))).getSingle();
  }

  /// Clinical helper to switch active patient profile.
  Future<void> switchActivePatient(String patientId, {DateTime? asOf}) async {
    final repository = PatientRepository(database);
    await repository.setActivePatient(patientId, asOf: asOf);
    container.read(activePatientIdProvider.notifier).state = patientId;
  }

  /// Clinical helper to get currently active patient profile.
  Future<Patient?> getActivePatient() async {
    final activeId = container.read(activePatientIdProvider);
    final repository = PatientRepository(database);
    if (activeId != null) {
      return repository.getPatientById(activeId);
    }
    return repository.getActivePatient();
  }

  /// Clinical helper to get all registered patient profiles.
  Future<List<Patient>> getAllPatients() async {
    return PatientRepository(database).getAllPatients();
  }

  /// Clinical helper to query a patient by ID.
  Future<Patient?> getPatient(String id) async {
    return PatientRepository(database).getPatientById(id);
  }

  /// Clinical helper to log a Dialysis Session.
  Future<DialysisSession> recordDialysisSession({
    String? id,
    required String patientId,
    required String sessionType,
    required DateTime startedAt,
    DateTime? endedAt,
    double? preWeightKg,
    double? postWeightKg,
    double? calculatedInterdialyticWeightGainKg,
    int? calculatedUltrafiltrationGoalMl,
    double? calculatedPostWeightDifferenceKg,
    int? actualFluidRemovedMl,
    String? notes,
    String? symptoms,
  }) async {
    final sessionId = id ?? generateUuid();
    final companion = DialysisSessionsCompanion.insert(
      id: drift.Value(sessionId),
      patientId: patientId,
      sessionType: sessionType,
      startedAt: startedAt,
      endedAt: drift.Value(endedAt),
      preWeightKg: drift.Value(preWeightKg),
      postWeightKg: drift.Value(postWeightKg),
      calculatedInterdialyticWeightGainKg: drift.Value(calculatedInterdialyticWeightGainKg),
      calculatedUltrafiltrationGoalMl: drift.Value(calculatedUltrafiltrationGoalMl),
      calculatedPostWeightDifferenceKg: drift.Value(calculatedPostWeightDifferenceKg),
      actualFluidRemovedMl: drift.Value(actualFluidRemovedMl),
      notes: drift.Value(notes),
      symptoms: drift.Value(symptoms),
    );
    await database.into(database.dialysisSessions).insert(companion);
    return (database.select(database.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Clinical helper to perform a pre-dialysis check-in, computing IDWG, UF goal, and logging access inspection.
  Future<DialysisSession> recordPreDialysisCheckIn({
    String? id,
    required String patientId,
    required double preWeightKg,
    int volumeAllowanceMl = 0,
    String? notes,
    DateTime? startedAt,
    bool? thrillPresent,
    bool? bruitPresent,
    bool? rednessPresent,
    bool? swellingPresent,
    bool? dischargePresent,
    bool? painPresent,
    String? inspectionNotes,
  }) async {
    final repository = DialysisSessionRepository(database);
    return repository.recordPreDialysisCheckIn(
      id: id,
      patientId: patientId,
      preWeightKg: preWeightKg,
      volumeAllowanceMl: volumeAllowanceMl,
      notes: notes,
      startedAt: startedAt,
      thrillPresent: thrillPresent,
      bruitPresent: bruitPresent,
      rednessPresent: rednessPresent,
      swellingPresent: swellingPresent,
      dischargePresent: dischargePresent,
      painPresent: painPresent,
      inspectionNotes: inspectionNotes,
    );
  }

  /// Clinical helper to complete a dialysis session with post-weight, variance calculation, and symptoms.
  Future<DialysisSession> recordPostDialysisSession({
    required String sessionId,
    required double postWeightKg,
    int? actualFluidRemovedMl,
    List<String>? symptoms,
    String? notes,
    DateTime? endedAt,
  }) async {
    final repository = DialysisSessionRepository(database);
    return repository.recordPostDialysisSession(
      sessionId: sessionId,
      postWeightKg: postWeightKg,
      actualFluidRemovedMl: actualFluidRemovedMl,
      symptoms: symptoms,
      notes: notes,
      endedAt: endedAt,
    );
  }

  /// Clinical helper to query dialysis sessions for a patient ordered most recent first.
  Future<List<DialysisSession>> getDialysisSessions(String patientId) async {
    return DialysisSessionRepository(database).getSessions(patientId);
  }

  /// Clinical helper to query the active (inProgress) dialysis session for a patient.
  Future<DialysisSession?> getActiveDialysisSession(String patientId) async {
    return DialysisSessionRepository(database).getActiveSession(patientId);
  }

  /// Clinical helper to cancel an in-progress dialysis session.
  Future<DialysisSession> cancelDialysisSession(String sessionId, {String? reason}) async {
    return DialysisSessionRepository(database).cancelDialysisSession(sessionId, reason: reason);
  }

  /// Clinical helper to record a Peritoneal Dialysis exchange.
  Future<DialysisSession> recordPeritonealExchange({
    String? id,
    required String patientId,
    required int inflowVolumeMl,
    required int drainVolumeMl,
    String? clarity,
    String? notes,
    DateTime? recordedAt,
  }) async {
    return DialysisSessionRepository(database).recordPeritonealExchange(
      id: id,
      patientId: patientId,
      inflowVolumeMl: inflowVolumeMl,
      drainVolumeMl: drainVolumeMl,
      clarity: clarity,
      notes: notes,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to record clinical symptoms.
  Future<DialysisSession> recordSymptomLog({
    String? id,
    required String patientId,
    required List<String> symptoms,
    String? notes,
    DateTime? recordedAt,
    String sessionType = 'symptom_log',
  }) async {
    return DialysisSessionRepository(database).recordSymptomLog(
      id: id,
      patientId: patientId,
      symptoms: symptoms,
      notes: notes,
      recordedAt: recordedAt,
      sessionType: sessionType,
    );
  }

  /// Clinical helper to query vascular access inspections for a patient ordered most recent first.
  Future<List<AccessInspection>> getAccessInspections(String patientId) async {
    return DialysisSessionRepository(database).getAccessInspections(patientId);
  }

  /// Clinical helper to log Blood Pressure with arm validation and Fistula Arm Safety Flag enforcement.
  Future<BloodPressureLog> recordBloodPressure({
    String? id,
    required String patientId,
    required int systolic,
    required int diastolic,
    required int pulse,
    required String armUsed,
    bool isSafeArm = true,
    required DateTime recordedAt,
  }) async {
    final repository = BloodPressureRepository(database);
    return repository.recordBloodPressure(
      id: id,
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      armUsed: armUsed,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to query hemodynamic blood pressure logs for a patient ordered by recordedAt descending.
  Future<List<BloodPressureLog>> getBloodPressureLogs(String patientId) async {
    return BloodPressureRepository(database).getBloodPressureLogs(patientId);
  }

  /// Alias for [getBloodPressureLogs].
  Future<List<BloodPressureLog>> getHemodynamicTrends(String patientId) => getBloodPressureLogs(patientId);

  /// Clinical helper to log Fluid Intake.
  Future<FluidIntakeLog> recordFluidIntake({
    String? id,
    required String patientId,
    required int volumeMl,
    required String beverageType,
    bool phosphateBinderTaken = false,
    required DateTime recordedAt,
  }) async {
    return FluidRepository(database).recordFluidIntake(
      id: id,
      patientId: patientId,
      volumeMl: volumeMl,
      beverageType: beverageType,
      phosphateBinderTaken: phosphateBinderTaken,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to update an existing Fluid Intake entry.
  Future<FluidIntakeLog> updateFluidIntake({
    required String id,
    int? volumeMl,
    String? beverageType,
    bool? phosphateBinderTaken,
    DateTime? recordedAt,
  }) async {
    return FluidRepository(database).updateFluidIntake(
      id: id,
      volumeMl: volumeMl,
      beverageType: beverageType,
      phosphateBinderTaken: phosphateBinderTaken,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to delete a Fluid Intake entry.
  Future<int> deleteFluidIntake(String id) async {
    return FluidRepository(database).deleteFluidIntake(id);
  }

  /// Clinical helper to log Fluid Output.
  Future<FluidOutputLog> recordFluidOutput({
    String? id,
    required String patientId,
    required int volumeMl,
    required String outputType,
    int? hematuriaGrade,
    required DateTime recordedAt,
  }) async {
    return FluidRepository(database).recordFluidOutput(
      id: id,
      patientId: patientId,
      volumeMl: volumeMl,
      outputType: outputType,
      hematuriaGrade: hematuriaGrade,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to query 24-hour Fluid Balance summary.
  Future<FluidBalanceSummary> get24HourFluidBalance(String patientId, {DateTime? asOf}) {
    return FluidRepository(database).get24HourFluidBalance(patientId, asOf: asOf);
  }

  /// Clinical helper to query fluid intake logs for a patient.
  Future<List<FluidIntakeLog>> getFluidIntakeLogs(String patientId, {DateTime? since}) {
    return FluidRepository(database).getFluidIntakeLogs(patientId, since: since);
  }

  /// Clinical helper to query fluid output logs for a patient.
  Future<List<FluidOutputLog>> getFluidOutputLogs(String patientId, {DateTime? since}) {
    return FluidRepository(database).getFluidOutputLogs(patientId, since: since);
  }

  /// Clinical helper to watch 24-hour Fluid Balance reactively.
  Stream<FluidBalanceSummary> watch24HourFluidBalance(String patientId) {
    return FluidRepository(database).watch24HourFluidBalance(patientId);
  }

  /// Clinical helper to log Catheter Lifecycle Event.
  Future<CatheterEvent> recordCatheterEvent({
    String? id,
    required String patientId,
    required String catheterType,
    required DateTime insertionDate,
    required DateTime replacementDueDate,
    required String status,
    String? notes,
  }) async {
    final catheterId = id ?? generateUuid();
    final companion = CatheterEventsCompanion.insert(
      id: drift.Value(catheterId),
      patientId: patientId,
      catheterType: catheterType,
      insertionDate: insertionDate,
      replacementDueDate: replacementDueDate,
      status: status,
      notes: drift.Value(notes),
    );
    await database.into(database.catheterEvents).insert(companion);
    return (database.select(database.catheterEvents)..where((tbl) => tbl.id.equals(catheterId))).getSingle();
  }

  /// Clinical helper to record a Urine Foley Catheter insertion event.
  Future<CatheterEvent> recordCatheterInsertion({
    String? id,
    required String patientId,
    required DateTime insertionDate,
    String? notes,
    String catheterType = 'foley',
    CatheterMaterial material = CatheterMaterial.latex14Day,
    int? customLifespanDays,
    int? bagEmptyingIntervalHours,
  }) {
    return CatheterRepository(database).recordCatheterInsertion(
      id: id,
      patientId: patientId,
      insertionDate: insertionDate,
      notes: notes,
      catheterType: catheterType,
      material: material,
      customLifespanDays: customLifespanDays,
      bagEmptyingIntervalHours: bagEmptyingIntervalHours,
    );
  }

  /// Clinical helper to record a Urine Foley Catheter replacement event.
  Future<CatheterEvent> recordCatheterReplacement({
    String? id,
    required String patientId,
    required DateTime replacementDate,
    String? notes,
    String catheterType = 'foley',
    CatheterMaterial material = CatheterMaterial.latex14Day,
    int? customLifespanDays,
    int? bagEmptyingIntervalHours,
  }) {
    return CatheterRepository(database).recordCatheterReplacement(
      id: id,
      patientId: patientId,
      replacementDate: replacementDate,
      notes: notes,
      catheterType: catheterType,
      material: material,
      customLifespanDays: customLifespanDays,
      bagEmptyingIntervalHours: bagEmptyingIntervalHours,
    );
  }

  /// Clinical helper to record a 1-tap Foley catheter bag emptied event with volume and hematuria grade.
  Future<BagEmptiedResult> recordBagEmptied({
    String? outputId,
    required String patientId,
    required int volumeMl,
    required int hematuriaGrade,
    DateTime? recordedAt,
  }) {
    return CatheterRepository(database).recordBagEmptied(
      outputId: outputId,
      patientId: patientId,
      volumeMl: volumeMl,
      hematuriaGrade: hematuriaGrade,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to query the currently active catheter for a patient.
  Future<CatheterEvent?> getActiveCatheter(String patientId) {
    return CatheterRepository(database).getActiveCatheter(patientId);
  }

  /// Clinical helper to query all catheter events for a patient.
  Future<List<CatheterEvent>> getCatheterHistory(String patientId) {
    return CatheterRepository(database).getCatheterHistory(patientId);
  }

  /// Clinical helper to evaluate 14-day lifespan summary and CAUTI risk status.
  Future<CatheterLifespanSummary?> evaluateCatheterLifespan(String patientId, {DateTime? asOf}) {
    return CatheterRepository(database).getCatheterLifespanSummary(patientId, asOf: asOf);
  }

  /// Clinical helper to log Vascular Access Inspection.
  Future<AccessInspection> recordAccessInspection({
    String? id,
    required String patientId,
    required String accessType,
    required String anatomicalLocation,
    bool? thrillPresent,
    bool? bruitPresent,
    bool? rednessPresent,
    bool? swellingPresent,
    bool? dischargePresent,
    bool? painPresent,
    String? notes,
    required DateTime recordedAt,
  }) async {
    final accessId = id ?? generateUuid();
    final companion = AccessInspectionsCompanion.insert(
      id: drift.Value(accessId),
      patientId: patientId,
      accessType: accessType,
      anatomicalLocation: anatomicalLocation,
      thrillPresent: drift.Value(thrillPresent),
      bruitPresent: drift.Value(bruitPresent),
      rednessPresent: drift.Value(rednessPresent),
      swellingPresent: drift.Value(swellingPresent),
      dischargePresent: drift.Value(dischargePresent),
      painPresent: drift.Value(painPresent),
      notes: drift.Value(notes),
      recordedAt: recordedAt,
    );
    await database.into(database.accessInspections).insert(companion);
    return (database.select(database.accessInspections)..where((tbl) => tbl.id.equals(accessId))).getSingle();
  }

  /// Clinical helper to compile modular clinical report data.
  Future<ClinicalReportData> compileModularClinicalReportData({
    required String patientId,
    required ModularReportConfig config,
    DateTime? asOf,
  }) {
    return ClinicalReportRepository(database).compileReportData(
      patientId: patientId,
      config: config,
      asOf: asOf,
    );
  }

  /// Clinical helper to compile Modular Clinical Report PDF [pw.Document] structure.
  Future<pw.Document> buildModularClinicalReportDocument({
    required String patientId,
    required ModularReportConfig config,
    DateTime? asOf,
    PdfPageFormat format = PdfPageFormat.a4,
    bool compress = true,
  }) async {
    final reportData = await compileModularClinicalReportData(
      patientId: patientId,
      config: config,
      asOf: asOf,
    );
    return ClinicalReportPdfGenerator().buildPdfDocument(reportData, format: format, compress: compress);
  }

  /// Clinical helper to generate Modular Clinical Report PDF bytes client-side.
  Future<Uint8List> generateModularClinicalReportPdf({
    required String patientId,
    required ModularReportConfig config,
    DateTime? asOf,
    PdfPageFormat format = PdfPageFormat.a4,
    bool compress = true,
  }) async {
    final reportData = await compileModularClinicalReportData(
      patientId: patientId,
      config: config,
      asOf: asOf,
    );
    return ClinicalReportPdfGenerator().generatePdfBytes(reportData, format: format, compress: compress);
  }

  /// Clinical helper to export a complete [PatientSyncBundle] for offline peer-to-peer exchange.
  Future<PatientSyncBundle> exportPatientSyncBundle(String patientId) {
    return PatientSyncBundle.fromDatabase(
      database: database,
      patientId: patientId,
    );
  }

  /// Clinical helper to ingest a [PatientSyncBundle] with deterministic conflict resolution.
  Future<SyncMergeResult> mergePatientSyncBundle(
    PatientSyncBundle bundle, {
    bool asCaregiverMirror = false,
  }) {
    return SyncMergeEngine(database).mergeBundle(
      bundle,
      asCaregiverMirror: asCaregiverMirror,
    );
  }

  /// Clinical helper to prescribe a medication regimen.
  Future<Medication> createMedication({
    String? id,
    required String patientId,
    required String name,
    required String dosage,
    required String frequency,
    String? instructions,
    bool isPhosphateBinder = false,
    bool isAntiHypertensive = false,
    bool isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationRepository(database).createMedication(
      id: id,
      patientId: patientId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      instructions: instructions,
      isPhosphateBinder: isPhosphateBinder,
      isAntiHypertensive: isAntiHypertensive,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Clinical helper to update a prescribed medication regimen.
  Future<Medication> updateMedication({
    required String id,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    bool? isPhosphateBinder,
    bool? isAntiHypertensive,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return MedicationRepository(database).updateMedication(
      id: id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      instructions: instructions,
      isPhosphateBinder: isPhosphateBinder,
      isAntiHypertensive: isAntiHypertensive,
      isActive: isActive,
      updatedAt: updatedAt,
    );
  }

  /// Clinical helper to query active prescribed medications for a patient.
  Future<List<Medication>> getActiveMedications(String patientId) {
    return MedicationRepository(database).getActiveMedications(patientId);
  }

  /// Clinical helper to query all medications for a patient.
  Future<List<Medication>> getAllMedications(String patientId) {
    return MedicationRepository(database).getAllMedications(patientId);
  }

  /// Clinical helper to record a 1-tap medication administration.
  Future<MedicationAdministration> recordMedicationAdministration({
    String? id,
    required String patientId,
    required String medicationId,
    DateTime? administeredAt,
    String? dosage,
    String? medicationName,
    String? notes,
  }) {
    return MedicationRepository(database).recordAdministration(
      id: id,
      patientId: patientId,
      medicationId: medicationId,
      administeredAt: administeredAt,
      dosage: dosage,
      medicationName: medicationName,
      notes: notes,
    );
  }

  /// Clinical helper to update a medication administration (to correct accidental entries).
  Future<MedicationAdministration> updateMedicationAdministration({
    required String id,
    DateTime? administeredAt,
    String? dosage,
    String? notes,
  }) {
    return MedicationRepository(database).updateAdministration(
      id: id,
      administeredAt: administeredAt,
      dosage: dosage,
      notes: notes,
    );
  }

  /// Clinical helper to delete a medication administration record.
  Future<int> deleteMedicationAdministration(String id) {
    return MedicationRepository(database).deleteAdministration(id);
  }

  /// Clinical helper to query medication administrations for a patient.
  Future<List<MedicationAdministration>> getMedicationAdministrations(
    String patientId, {
    DateTime? since,
  }) {
    return MedicationRepository(database).getAdministrations(patientId, since: since);
  }

  /// Clinical helper to check if patient has active phosphate binders.
  Future<bool> hasActivePhosphateBinders(String patientId) {
    return MedicationRepository(database).hasActivePhosphateBinders(patientId);
  }

  /// Clinical helper to query active phosphate binders.
  Future<List<Medication>> getActivePhosphateBinders(String patientId) {
    return MedicationRepository(database).getActivePhosphateBinders(patientId);
  }

  /// Tears down and disposes container and in-memory database connections.
  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

/// Factory function to construct an isolated [NephroTestHarness] with an in-memory database.
NephroTestHarness createNephroTestHarness() {
  final inMemoryDb = AppDatabase(
    drift.DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(inMemoryDb),
    ],
  );

  return NephroTestHarness(
    container: container,
    database: inMemoryDb,
  );
}
