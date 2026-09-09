import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/catheter_lifespan_rules.dart';

/// Result of recording a 1-tap bag emptying action.
class BagEmptiedResult {
  final FluidOutputLog outputLog;
  final CatheterEvent catheter;

  const BagEmptiedResult({
    required this.outputLog,
    required this.catheter,
  });
}

/// Repository managing Urine Foley Catheter lifecycle persistence in Drift SQLite,
/// configurable material lifespan tracking, collection bag emptying reminders,
/// and reactive stream subscriptions.
class CatheterRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  CatheterRepository(this._db);

  /// Ensures that the patient profile exists or throws [ArgumentError].
  Future<Patient> _ensurePatientExists(String patientId) async {
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }
    return patient;
  }

  /// Records an indwelling Urine Foley Catheter insertion event.
  ///
  /// Supports configurable materials (14-day latex, 30-day silicone, 90-day silicone, custom),
  /// calculates the replacement due date accordingly, sets status to 'active',
  /// and marks any previous active catheter as 'replaced'.
  Future<CatheterEvent> recordCatheterInsertion({
    String? id,
    required String patientId,
    required DateTime insertionDate,
    CatheterMaterial material = CatheterMaterial.latex14Day,
    int? customLifespanDays,
    int? bagEmptyingIntervalHours,
    String? notes,
    String catheterType = 'foley',
  }) async {
    await _ensurePatientExists(patientId);

    final now = DateTime.now().toUtc();
    final insertUtc = insertionDate.toUtc();
    final totalLifespan = (material == CatheterMaterial.custom && customLifespanDays != null && customLifespanDays > 0)
        ? customLifespanDays
        : material.defaultLifespanDays;
    final dueDateUtc = insertUtc.add(Duration(days: totalLifespan));
    final catheterId = id ?? _uuid.v4();

    // Mark any existing active catheter for this patient as 'replaced'
    await (_db.update(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('active')))
        .write(
      CatheterEventsCompanion(
        status: const drift.Value('replaced'),
        updatedAt: drift.Value(now),
      ),
    );

    final companion = CatheterEventsCompanion.insert(
      id: drift.Value(catheterId),
      patientId: patientId,
      catheterType: catheterType,
      insertionDate: insertUtc,
      replacementDueDate: dueDateUtc,
      status: 'active',
      notes: drift.Value(notes),
      material: drift.Value(material.name),
      lifespanDays: drift.Value(totalLifespan),
      bagEmptyingIntervalHours: drift.Value(bagEmptyingIntervalHours),
      lastBagEmptiedAt: const drift.Value(null),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.catheterEvents).insert(companion);
    return (_db.select(_db.catheterEvents)..where((tbl) => tbl.id.equals(catheterId))).getSingle();
  }

  /// Records a catheter replacement event, retiring active catheter and starting a new cycle.
  Future<CatheterEvent> recordCatheterReplacement({
    String? id,
    required String patientId,
    required DateTime replacementDate,
    CatheterMaterial material = CatheterMaterial.latex14Day,
    int? customLifespanDays,
    int? bagEmptyingIntervalHours,
    String? notes,
    String catheterType = 'foley',
  }) async {
    return recordCatheterInsertion(
      id: id,
      patientId: patientId,
      insertionDate: replacementDate,
      material: material,
      customLifespanDays: customLifespanDays,
      bagEmptyingIntervalHours: bagEmptyingIntervalHours,
      notes: notes,
      catheterType: catheterType,
    );
  }

  /// Records a 1-tap "Bag Emptied" event:
  /// Captures evacuated volume and Hematuria Grade (1 to 4) into [FluidOutputLogs]
  /// and updates the active catheter's [lastBagEmptiedAt] timestamp in one unified step.
  Future<BagEmptiedResult> recordBagEmptied({
    String? outputId,
    required String patientId,
    required int volumeMl,
    required int hematuriaGrade,
    DateTime? recordedAt,
  }) async {
    await _ensurePatientExists(patientId);

    if (volumeMl <= 0) {
      throw ArgumentError('Evacuated volume must be greater than zero mL.');
    }
    if (hematuriaGrade < 1 || hematuriaGrade > 4) {
      throw ArgumentError('Hematuria grade must be between 1 and 4 per CONTEXT.md.');
    }

    final activeCatheter = await getActiveCatheter(patientId);
    if (activeCatheter == null) {
      throw StateError('Cannot record bag emptying without an active catheter for patient: $patientId');
    }

    final now = DateTime.now().toUtc();
    final timestamp = recordedAt?.toUtc() ?? now;
    final logId = outputId ?? _uuid.v4();

    return _db.transaction(() async {
      final logCompanion = FluidOutputLogsCompanion.insert(
        id: drift.Value(logId),
        patientId: patientId,
        volumeMl: volumeMl,
        outputType: 'urine',
        hematuriaGrade: drift.Value(hematuriaGrade),
        recordedAt: timestamp,
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );
      await _db.into(_db.fluidOutputLogs).insert(logCompanion);
      final outputLog = await (_db.select(_db.fluidOutputLogs)..where((tbl) => tbl.id.equals(logId))).getSingle();

      await (_db.update(_db.catheterEvents)..where((tbl) => tbl.id.equals(activeCatheter.id))).write(
        CatheterEventsCompanion(
          lastBagEmptiedAt: drift.Value(timestamp),
          updatedAt: drift.Value(now),
        ),
      );
      final updatedCatheter =
          await (_db.select(_db.catheterEvents)..where((tbl) => tbl.id.equals(activeCatheter.id))).getSingle();

      return BagEmptiedResult(
        outputLog: outputLog,
        catheter: updatedCatheter,
      );
    });
  }

  /// Queries the currently active catheter for a patient.
  Future<CatheterEvent?> getActiveCatheter(String patientId) async {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('active'))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Observes the active catheter for a patient reactively.
  Stream<CatheterEvent?> watchActiveCatheter(String patientId) {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('active'))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Queries all catheter events for a patient ordered most recent first.
  Future<List<CatheterEvent>> getCatheterHistory(String patientId) async {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)]))
        .get();
  }

  /// Observes all catheter events for a patient reactively.
  Stream<List<CatheterEvent>> watchCatheterHistory(String patientId) {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)]))
        .watch();
  }

  CatheterLifespanSummary _buildSummary(CatheterEvent active, {DateTime? asOf}) {
    return CatheterLifespanRules.evaluateLifespan(
      insertionDate: active.insertionDate,
      replacementDueDate: active.replacementDueDate,
      asOf: asOf,
      material: CatheterMaterial.fromString(active.material),
      customLifespanDays: active.lifespanDays,
      bagEmptyingIntervalHours: active.bagEmptyingIntervalHours,
      lastBagEmptiedAt: active.lastBagEmptiedAt,
    );
  }

  /// Evaluates the lifespan summary for a patient's active catheter.
  Future<CatheterLifespanSummary?> getCatheterLifespanSummary(
    String patientId, {
    DateTime? asOf,
  }) async {
    final active = await getActiveCatheter(patientId);
    if (active == null) return null;
    return _buildSummary(active, asOf: asOf);
  }

  /// Observes the lifespan summary for a patient's active catheter reactively.
  Stream<CatheterLifespanSummary?> watchCatheterLifespanSummary(
    String patientId, {
    DateTime? asOf,
  }) {
    return watchActiveCatheter(patientId).map((active) {
      if (active == null) return null;
      return _buildSummary(active, asOf: asOf);
    });
  }
}

/// Provider for [CatheterRepository].
final catheterRepositoryProvider = Provider<CatheterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CatheterRepository(db);
});

/// Stream provider for the active catheter of a patient.
final activeCatheterStreamProvider = StreamProvider.family<CatheterEvent?, String>((ref, patientId) {
  final repository = ref.watch(catheterRepositoryProvider);
  return repository.watchActiveCatheter(patientId);
});

/// Stream provider for the catheter events history of a patient.
final catheterHistoryStreamProvider = StreamProvider.family<List<CatheterEvent>, String>((ref, patientId) {
  final repository = ref.watch(catheterRepositoryProvider);
  return repository.watchCatheterHistory(patientId);
});

/// Stream provider for the 14-day catheter lifespan summary of a patient.
final catheterLifespanSummaryStreamProvider =
    StreamProvider.family<CatheterLifespanSummary?, String>((ref, patientId) {
  final repository = ref.watch(catheterRepositoryProvider);
  return repository.watchCatheterLifespanSummary(patientId);
});
