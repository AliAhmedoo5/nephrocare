import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/fluid_balance_summary.dart';
import '../domain/fluid_calculation_rules.dart';

/// Repository managing fluid intake and output persistence in Drift SQLite,
/// dynamic 24-hour fluid balance rollups, and reactive Riverpod stream subscriptions.
class FluidRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  FluidRepository(this._db);

  /// Ensures that patient exists in the database or throws [ArgumentError].
  Future<Patient> _ensurePatientExists(String patientId) async {
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }
    return patient;
  }

  /// Records a fluid intake entry with UUIDv4 and updated_at metadata.
  Future<FluidIntakeLog> recordFluidIntake({
    String? id,
    required String patientId,
    required int volumeMl,
    required String beverageType,
    bool phosphateBinderTaken = false,
    DateTime? recordedAt,
  }) async {
    await _ensurePatientExists(patientId);

    if (volumeMl <= 0) {
      throw ArgumentError('Fluid intake volume must be greater than zero.');
    }

    final intakeId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final timestamp = recordedAt?.toUtc() ?? now;

    final companion = FluidIntakeLogsCompanion.insert(
      id: drift.Value(intakeId),
      patientId: patientId,
      volumeMl: volumeMl,
      beverageType: beverageType,
      phosphateBinderTaken: drift.Value(phosphateBinderTaken),
      recordedAt: timestamp,
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.fluidIntakeLogs).insert(companion);
    return (_db.select(_db.fluidIntakeLogs)..where((tbl) => tbl.id.equals(intakeId))).getSingle();
  }

  /// Updates an existing fluid intake entry and updates its updatedAt timestamp.
  Future<FluidIntakeLog> updateFluidIntake({
    required String id,
    int? volumeMl,
    String? beverageType,
    bool? phosphateBinderTaken,
    DateTime? recordedAt,
  }) async {
    final existing = await (_db.select(_db.fluidIntakeLogs)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw ArgumentError('Fluid intake log not found with id: $id');
    }

    if (volumeMl != null && volumeMl <= 0) {
      throw ArgumentError('Fluid intake volume must be greater than zero.');
    }

    final now = DateTime.now().toUtc();
    final companion = FluidIntakeLogsCompanion(
      volumeMl: volumeMl != null ? drift.Value(volumeMl) : const drift.Value.absent(),
      beverageType: beverageType != null ? drift.Value(beverageType) : const drift.Value.absent(),
      phosphateBinderTaken: phosphateBinderTaken != null ? drift.Value(phosphateBinderTaken) : const drift.Value.absent(),
      recordedAt: recordedAt != null ? drift.Value(recordedAt.toUtc()) : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(_db.fluidIntakeLogs)..where((tbl) => tbl.id.equals(id))).write(companion);
    return (_db.select(_db.fluidIntakeLogs)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  /// Deletes a fluid intake entry by ID.
  Future<int> deleteFluidIntake(String id) async {
    return (_db.delete(_db.fluidIntakeLogs)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Deletes a fluid output entry by ID.
  Future<int> deleteFluidOutput(String id) async {
    return (_db.delete(_db.fluidOutputLogs)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Records a fluid output / evacuation entry with UUIDv4 and updated_at metadata.
  Future<FluidOutputLog> recordFluidOutput({
    String? id,
    required String patientId,
    required int volumeMl,
    required String outputType,
    int? hematuriaGrade,
    DateTime? recordedAt,
  }) async {
    await _ensurePatientExists(patientId);

    if (volumeMl <= 0) {
      throw ArgumentError('Fluid output volume must be greater than zero.');
    }

    // 2. Validate Hematuria Grade per CONTEXT.md (1 to 4)
    if (hematuriaGrade != null && (hematuriaGrade < 1 || hematuriaGrade > 4)) {
      throw ArgumentError('Hematuria grade must be between 1 and 4 per CONTEXT.md');
    }

    final outputId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final timestamp = recordedAt?.toUtc() ?? now;

    final companion = FluidOutputLogsCompanion.insert(
      id: drift.Value(outputId),
      patientId: patientId,
      volumeMl: volumeMl,
      outputType: outputType,
      hematuriaGrade: drift.Value(hematuriaGrade),
      recordedAt: timestamp,
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.fluidOutputLogs).insert(companion);
    return (_db.select(_db.fluidOutputLogs)..where((tbl) => tbl.id.equals(outputId))).getSingle();
  }

  /// Queries fluid intake logs for a patient ordered most recent first.
  Future<List<FluidIntakeLog>> getFluidIntakeLogs(String patientId, {DateTime? since}) async {
    final query = _db.select(_db.fluidIntakeLogs)..where((tbl) => tbl.patientId.equals(patientId));
    if (since != null) {
      query.where((tbl) => tbl.recordedAt.isBiggerOrEqualValue(since.toUtc()));
    }
    query.orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]);
    return query.get();
  }

  /// Observes fluid intake logs for a patient reactively.
  Stream<List<FluidIntakeLog>> watchFluidIntakeLogs(String patientId, {DateTime? since}) {
    final query = _db.select(_db.fluidIntakeLogs)..where((tbl) => tbl.patientId.equals(patientId));
    if (since != null) {
      query.where((tbl) => tbl.recordedAt.isBiggerOrEqualValue(since.toUtc()));
    }
    query.orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]);
    return query.watch();
  }

  /// Queries fluid output logs for a patient ordered most recent first.
  Future<List<FluidOutputLog>> getFluidOutputLogs(String patientId, {DateTime? since}) async {
    final query = _db.select(_db.fluidOutputLogs)..where((tbl) => tbl.patientId.equals(patientId));
    if (since != null) {
      query.where((tbl) => tbl.recordedAt.isBiggerOrEqualValue(since.toUtc()));
    }
    query.orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]);
    return query.get();
  }

  /// Observes fluid output logs for a patient reactively.
  Stream<List<FluidOutputLog>> watchFluidOutputLogs(String patientId, {DateTime? since}) {
    final query = _db.select(_db.fluidOutputLogs)..where((tbl) => tbl.patientId.equals(patientId));
    if (since != null) {
      query.where((tbl) => tbl.recordedAt.isBiggerOrEqualValue(since.toUtc()));
    }
    query.orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]);
    return query.watch();
  }

  /// Computes the 24-hour Fluid Balance and cumulative intake progression for a patient.
  Future<FluidBalanceSummary> get24HourFluidBalance(String patientId, {DateTime? asOf}) async {
    final referenceTime = asOf?.toUtc() ?? DateTime.now().toUtc();
    final windowStart = referenceTime.subtract(const Duration(hours: 24));

    // 1. Fetch patient profile
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    // 2. Fetch 24-hour intake logs
    final intakeLogs = await (_db.select(_db.fluidIntakeLogs)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.recordedAt.isBiggerOrEqualValue(windowStart) &
              tbl.recordedAt.isSmallerOrEqualValue(referenceTime)))
        .get();

    // 3. Fetch 24-hour output logs
    final outputLogs = await (_db.select(_db.fluidOutputLogs)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.recordedAt.isBiggerOrEqualValue(windowStart) &
              tbl.recordedAt.isSmallerOrEqualValue(referenceTime)))
        .get();

    final totalIntakeMl = intakeLogs.fold<int>(0, (sum, log) => sum + log.volumeMl);
    final totalOutputLogsMl = outputLogs.fold<int>(0, (sum, log) => sum + log.volumeMl);

    // 4. Factor in hemodialysis session actual ultrafiltration volume
    final sessions = await (_db.select(_db.dialysisSessions)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.startedAt.isBiggerOrEqualValue(windowStart) &
              tbl.startedAt.isSmallerOrEqualValue(referenceTime) &
              tbl.actualFluidRemovedMl.isNotNull()))
        .get();

    int dialysisUfMl = 0;
    for (final session in sessions) {
      if (session.actualFluidRemovedMl != null && session.actualFluidRemovedMl! > 0) {
        dialysisUfMl += session.actualFluidRemovedMl!;
      }
    }

    final totalOutputMl = totalOutputLogsMl + dialysisUfMl;

    return FluidCalculationRules.buildSummary(
      totalIntakeMl: totalIntakeMl,
      totalOutputMl: totalOutputMl,
      dailyFluidAllowanceMl: patient.dailyFluidAllowanceMl,
    );
  }

  /// Observes 24-hour Fluid Balance and cumulative intake progression reactively.
  Stream<FluidBalanceSummary> watch24HourFluidBalance(String patientId) async* {
    yield await get24HourFluidBalance(patientId);

    final updateStream = _db.tableUpdates(
      drift.TableUpdateQuery.onAllTables([
        _db.fluidIntakeLogs,
        _db.fluidOutputLogs,
        _db.dialysisSessions,
        _db.patients,
      ]),
    );

    await for (final _ in updateStream) {
      yield await get24HourFluidBalance(patientId);
    }
  }
}

/// Provider for [FluidRepository].
final fluidRepositoryProvider = Provider<FluidRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FluidRepository(db);
});

/// Stream provider for a patient's fluid intake logs.
final fluidIntakeLogsStreamProvider = StreamProvider.family<List<FluidIntakeLog>, String>((ref, patientId) {
  final repository = ref.watch(fluidRepositoryProvider);
  return repository.watchFluidIntakeLogs(patientId);
});

/// Stream provider for a patient's fluid output logs.
final fluidOutputLogsStreamProvider = StreamProvider.family<List<FluidOutputLog>, String>((ref, patientId) {
  final repository = ref.watch(fluidRepositoryProvider);
  return repository.watchFluidOutputLogs(patientId);
});

/// Stream provider for today's fluid intake logs.
final todayFluidIntakeLogsStreamProvider = StreamProvider.family<List<FluidIntakeLog>, String>((ref, patientId) {
  final repository = ref.watch(fluidRepositoryProvider);
  final now = DateTime.now().toUtc();
  final startOfDay = DateTime.utc(now.year, now.month, now.day);
  return repository.watchFluidIntakeLogs(patientId, since: startOfDay);
});

/// Stream provider for today's fluid output logs.
final todayFluidOutputLogsStreamProvider = StreamProvider.family<List<FluidOutputLog>, String>((ref, patientId) {
  final repository = ref.watch(fluidRepositoryProvider);
  final now = DateTime.now().toUtc();
  final startOfDay = DateTime.utc(now.year, now.month, now.day);
  return repository.watchFluidOutputLogs(patientId, since: startOfDay);
});

/// Stream provider for 24-hour fluid balance and progression summary.
final fluidBalance24hStreamProvider = StreamProvider.family<FluidBalanceSummary, String>((ref, patientId) {
  final repository = ref.watch(fluidRepositoryProvider);
  return repository.watch24HourFluidBalance(patientId);
});
