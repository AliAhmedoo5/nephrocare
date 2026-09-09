import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

// 1. Patients Table
class Patients extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text()();
  TextColumn get diagnosis => text()(); // hemodialysis, peritonealDialysis, nonDialysisCkd, urologicalCatheter
  RealColumn get prescribedDryWeightKg => real().nullable()();
  IntColumn get dailyFluidAllowanceMl => integer().nullable()();
  /// Type of vascular access (e.g., 'arteriovenousFistula', 'arteriovenousGraft', 'dialysisCentralLine', 'peritonealDialysisAccess', 'none').
  TextColumn get vascularAccessType => text().nullable()();
  /// Designated arm bearing vascular access (e.g., 'leftArm', 'rightArm', 'none').
  /// Used to enforce the Fistula Arm Safety Flag per ADR-0003.
  TextColumn get fistulaArmLocation => text().nullable()();
  BoolColumn get isCaregiverMirror => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Dialysis Sessions Table
class DialysisSessions extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get patientId => text().references(Patients, #id)();
  TextColumn get sessionType => text()(); // hemodialysis, peritoneal
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get preWeightKg => real().nullable()();
  RealColumn get postWeightKg => real().nullable()();
  RealColumn get calculatedInterdialyticWeightGainKg => real().nullable()();
  IntColumn get calculatedUltrafiltrationGoalMl => integer().nullable()();
  RealColumn get calculatedPostWeightDifferenceKg => real().nullable()();
  IntColumn get actualFluidRemovedMl => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get symptoms => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. Blood Pressure Logs Table
class BloodPressureLogs extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get patientId => text().references(Patients, #id)();
  IntColumn get systolic => integer()();
  IntColumn get diastolic => integer()();
  IntColumn get pulse => integer()();
  TextColumn get armUsed => text()(); // leftArm, rightArm
  BoolColumn get isSafeArm => boolean().withDefault(const Constant(true))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. Fluid Intake Logs Table
class FluidIntakeLogs extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get patientId => text().references(Patients, #id)();
  IntColumn get volumeMl => integer()();
  TextColumn get beverageType => text()();
  BoolColumn get phosphateBinderTaken => boolean().withDefault(const Constant(false))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Fluid Output Logs Table
class FluidOutputLogs extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get patientId => text().references(Patients, #id)();
  IntColumn get volumeMl => integer()();
  TextColumn get outputType => text()(); // urine, peritonealDrain, ultrafiltration
  IntColumn get hematuriaGrade => integer().nullable()(); // 1 to 4 per CONTEXT.md
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

// 6. Catheter Events Table
class CatheterEvents extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get patientId => text().references(Patients, #id)();
  TextColumn get catheterType => text()(); // foley, etc.
  DateTimeColumn get insertionDate => dateTime()();
  DateTimeColumn get replacementDueDate => dateTime()();
  TextColumn get status => text()(); // active, replaced, removed
  TextColumn get notes => text().nullable()();
  TextColumn get material => text().withDefault(const Constant('latex14Day'))();
  IntColumn get lifespanDays => integer().withDefault(const Constant(14))();
  IntColumn get bagEmptyingIntervalHours => integer().nullable()();
  DateTimeColumn get lastBagEmptiedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

// 7. Access Inspections Table
class AccessInspections extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get patientId => text().references(Patients, #id)();
  TextColumn get accessType => text()(); // arteriovenousFistula, arteriovenousGraft, dialysisCentralLine, peritonealDialysisAccess
  TextColumn get anatomicalLocation => text()(); // leftArm, rightArm, chest, abdomen
  BoolColumn get thrillPresent => boolean().nullable()();
  BoolColumn get bruitPresent => boolean().nullable()();
  BoolColumn get rednessPresent => boolean().nullable()();
  BoolColumn get swellingPresent => boolean().nullable()();
  BoolColumn get dischargePresent => boolean().nullable()();
  BoolColumn get painPresent => boolean().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Patients,
  DialysisSessions,
  BloodPressureLogs,
  FluidIntakeLogs,
  FluidOutputLogs,
  CatheterEvents,
  AccessInspections,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nephrocare',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
