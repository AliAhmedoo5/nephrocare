import '../../../core/database/app_database.dart';

/// Relational data transfer container bundling patient profiles and all
/// associated clinical records for offline peer-to-peer exchange across devices.
///
/// Supports single-patient exports as well as multi-patient database synchronization.
class PatientSyncBundle {
  final int schemaVersion;
  final DateTime exportedAt;
  final List<Patient> patients;
  final List<DialysisSession> dialysisSessions;
  final List<BloodPressureLog> bloodPressureLogs;
  final List<FluidIntakeLog> fluidIntakeLogs;
  final List<FluidOutputLog> fluidOutputLogs;
  final List<CatheterEvent> catheterEvents;
  final List<AccessInspection> accessInspections;
  final List<Medication> medications;
  final List<MedicationAdministration> medicationAdministrations;

  /// Convenience getter for single-patient operations.
  Patient get patient => patients.first;

  PatientSyncBundle({
    this.schemaVersion = 2,
    required this.exportedAt,
    List<Patient>? patients,
    Patient? patient,
    this.dialysisSessions = const [],
    this.bloodPressureLogs = const [],
    this.fluidIntakeLogs = const [],
    this.fluidOutputLogs = const [],
    this.catheterEvents = const [],
    this.accessInspections = const [],
    this.medications = const [],
    this.medicationAdministrations = const [],
  }) : patients = patients ?? (patient != null ? [patient] : const []);

  /// Gathers clinical records for a given patient or the entire multi-patient database.
  static Future<PatientSyncBundle> fromDatabase({
    required AppDatabase database,
    String? patientId,
  }) async {
    final List<Patient> patients;
    final List<DialysisSession> sessions;
    final List<BloodPressureLog> bpLogs;
    final List<FluidIntakeLog> intakeLogs;
    final List<FluidOutputLog> outputLogs;
    final List<CatheterEvent> catheters;
    final List<AccessInspection> inspections;
    final List<Medication> meds;
    final List<MedicationAdministration> admins;

    if (patientId != null) {
      final p = await (database.select(database.patients)
            ..where((tbl) => tbl.id.equals(patientId)))
          .getSingle();
      patients = [p];
      sessions = await (database.select(database.dialysisSessions)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      bpLogs = await (database.select(database.bloodPressureLogs)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      intakeLogs = await (database.select(database.fluidIntakeLogs)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      outputLogs = await (database.select(database.fluidOutputLogs)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      catheters = await (database.select(database.catheterEvents)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      inspections = await (database.select(database.accessInspections)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      meds = await (database.select(database.medications)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
      admins = await (database.select(database.medicationAdministrations)
            ..where((tbl) => tbl.patientId.equals(patientId)))
          .get();
    } else {
      patients = await database.select(database.patients).get();
      sessions = await database.select(database.dialysisSessions).get();
      bpLogs = await database.select(database.bloodPressureLogs).get();
      intakeLogs = await database.select(database.fluidIntakeLogs).get();
      outputLogs = await database.select(database.fluidOutputLogs).get();
      catheters = await database.select(database.catheterEvents).get();
      inspections = await database.select(database.accessInspections).get();
      meds = await database.select(database.medications).get();
      admins = await database.select(database.medicationAdministrations).get();
    }

    return PatientSyncBundle(
      schemaVersion: 2,
      exportedAt: DateTime.now().toUtc(),
      patients: patients,
      dialysisSessions: sessions,
      bloodPressureLogs: bpLogs,
      fluidIntakeLogs: intakeLogs,
      fluidOutputLogs: outputLogs,
      catheterEvents: catheters,
      accessInspections: inspections,
      medications: meds,
      medicationAdministrations: admins,
    );
  }

  /// Serializes the relational bundle into a JSON map.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'patients': patients.map((e) => e.toJson()).toList(),
        'dialysisSessions': dialysisSessions.map((e) => e.toJson()).toList(),
        'bloodPressureLogs': bloodPressureLogs.map((e) => e.toJson()).toList(),
        'fluidIntakeLogs': fluidIntakeLogs.map((e) => e.toJson()).toList(),
        'fluidOutputLogs': fluidOutputLogs.map((e) => e.toJson()).toList(),
        'catheterEvents': catheterEvents.map((e) => e.toJson()).toList(),
        'accessInspections': accessInspections.map((e) => e.toJson()).toList(),
        'medications': medications.map((e) => e.toJson()).toList(),
        'medicationAdministrations':
            medicationAdministrations.map((e) => e.toJson()).toList(),
      };

  /// Constructs a [PatientSyncBundle] from a serialized JSON map.
  factory PatientSyncBundle.fromJson(Map<String, dynamic> json) {
    final patientsJson = json['patients'] as List<dynamic>?;
    final List<Patient> parsedPatients;
    if (patientsJson != null && patientsJson.isNotEmpty) {
      parsedPatients = patientsJson
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['patient'] != null) {
      parsedPatients = [
        Patient.fromJson(json['patient'] as Map<String, dynamic>),
      ];
    } else {
      parsedPatients = [];
    }

    return PatientSyncBundle(
      schemaVersion: json['schemaVersion'] as int? ?? 2,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      patients: parsedPatients,
      dialysisSessions: (json['dialysisSessions'] as List<dynamic>? ?? [])
          .map((e) => DialysisSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      bloodPressureLogs: (json['bloodPressureLogs'] as List<dynamic>? ?? [])
          .map((e) => BloodPressureLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      fluidIntakeLogs: (json['fluidIntakeLogs'] as List<dynamic>? ?? [])
          .map((e) => FluidIntakeLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      fluidOutputLogs: (json['fluidOutputLogs'] as List<dynamic>? ?? [])
          .map((e) => FluidOutputLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      catheterEvents: (json['catheterEvents'] as List<dynamic>? ?? [])
          .map((e) => CatheterEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      accessInspections: (json['accessInspections'] as List<dynamic>? ?? [])
          .map((e) => AccessInspection.fromJson(e as Map<String, dynamic>))
          .toList(),
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList(),
      medicationAdministrations:
          (json['medicationAdministrations'] as List<dynamic>? ?? [])
              .map((e) =>
                  MedicationAdministration.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
