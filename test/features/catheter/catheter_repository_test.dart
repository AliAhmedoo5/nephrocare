import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/features/catheter/data/catheter_repository.dart';
import 'package:nephrocare/src/features/catheter/domain/catheter_lifespan_rules.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('CatheterRepository Drift SQLite Persistence Seam', () {
    late AppDatabase db;
    late CatheterRepository repository;
    final uuid = const Uuid();
    late String patientId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = CatheterRepository(db);

      patientId = uuid.v4();
      await db.into(db.patients).insert(
            PatientsCompanion.insert(
              id: drift.Value(patientId),
              name: 'Robert Vance',
              diagnosis: 'urologicalCatheter',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('Records catheter insertion with UUIDv4, 14-day replacementDueDate, and updatedAt', () async {
      final insertionDate = DateTime.utc(2026, 9, 1, 9, 0);

      final catheter = await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: insertionDate,
        notes: '16 Fr Foley catheter inserted cleanly.',
      );

      expect(catheter.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(catheter.id),
        isTrue,
      );
      expect(catheter.patientId, equals(patientId));
      expect(catheter.catheterType, equals('foley'));
      expect(catheter.status, equals('active'));
      expect(catheter.insertionDate.isAtSameMomentAs(insertionDate), isTrue);
      expect(catheter.replacementDueDate.isAtSameMomentAs(insertionDate.add(const Duration(days: 14))), isTrue);
      expect(catheter.notes, equals('16 Fr Foley catheter inserted cleanly.'));
      expect(catheter.createdAt, isNotNull);
      expect(catheter.updatedAt, isNotNull);

      // Verify active catheter lookup
      final active = await repository.getActiveCatheter(patientId);
      expect(active, isNotNull);
      expect(active!.id, equals(catheter.id));
    });

    test('Recording catheter replacement marks previous active catheter as replaced and starts new 14-day cycle', () async {
      final initialDate = DateTime.utc(2026, 9, 1, 9, 0);
      final initialCatheter = await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: initialDate,
        notes: 'Initial insertion',
      );
      expect(initialCatheter.status, equals('active'));

      // 14 days later: replacement event
      final replacementDate = DateTime.utc(2026, 9, 15, 10, 0);
      final newCatheter = await repository.recordCatheterReplacement(
        patientId: patientId,
        replacementDate: replacementDate,
        notes: 'Routine scheduled 14-day exchange',
      );

      expect(newCatheter.id, isNot(equals(initialCatheter.id)));
      expect(newCatheter.status, equals('active'));
      expect(newCatheter.insertionDate.isAtSameMomentAs(replacementDate), isTrue);
      expect(newCatheter.replacementDueDate.isAtSameMomentAs(replacementDate.add(const Duration(days: 14))), isTrue);

      // Verify previous catheter was updated to replaced status
      final allEvents = await repository.getCatheterHistory(patientId);
      expect(allEvents.length, equals(2));
      final previous = allEvents.firstWhere((e) => e.id == initialCatheter.id);
      expect(previous.status, equals('replaced'));
      expect(previous.updatedAt, isNotNull);

      // Verify active catheter is the new one
      final active = await repository.getActiveCatheter(patientId);
      expect(active!.id, equals(newCatheter.id));
      expect(active.status, equals('active'));
    });

    test('Evaluates 14-day lifespan summary reactively for active catheter', () async {
      final initialDate = DateTime.utc(2026, 9, 1, 8, 0);
      await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: initialDate,
      );

      // Test asOf day 5 (Green)
      final summaryDay5 = await repository.getCatheterLifespanSummary(
        patientId,
        asOf: DateTime.utc(2026, 9, 5, 8, 0),
      );
      expect(summaryDay5, isNotNull);
      expect(summaryDay5!.status, equals(CatheterLifespanStatus.green));
      expect(summaryDay5.dayOfCycle, equals(5));

      // Test asOf day 12 (Amber)
      final summaryDay12 = await repository.getCatheterLifespanSummary(
        patientId,
        asOf: DateTime.utc(2026, 9, 12, 8, 0),
      );
      expect(summaryDay12, isNotNull);
      expect(summaryDay12!.status, equals(CatheterLifespanStatus.amber));
      expect(summaryDay12.dayOfCycle, equals(12));

      // Test asOf day 16 (Red - CAUTI Risk Window)
      final summaryDay16 = await repository.getCatheterLifespanSummary(
        patientId,
        asOf: DateTime.utc(2026, 9, 16, 8, 0),
      );
      expect(summaryDay16, isNotNull);
      expect(summaryDay16!.status, equals(CatheterLifespanStatus.red));
      expect(summaryDay16.isCautiRiskActive, isTrue);
    });

    test('Throws ArgumentError if recording for non-existent patient', () async {
      expect(
        () => repository.recordCatheterInsertion(
          patientId: 'non-existent-id',
          insertionDate: DateTime.now().toUtc(),
        ),
        throwsArgumentError,
      );
    });

    test('Records catheter with configurable material (30-day silicone) and bag emptying interval', () async {
      final insertionDate = DateTime.utc(2026, 9, 1, 8, 0);

      final catheter = await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone30Day,
        bagEmptyingIntervalHours: 6,
        notes: '30-day silicone Foley catheter placed.',
      );

      expect(catheter.material, equals('silicone30Day'));
      expect(catheter.lifespanDays, equals(30));
      expect(catheter.bagEmptyingIntervalHours, equals(6));
      expect(catheter.replacementDueDate.isAtSameMomentAs(insertionDate.add(const Duration(days: 30))), isTrue);

      final summary = await repository.getCatheterLifespanSummary(
        patientId,
        asOf: DateTime.utc(2026, 9, 1, 11, 0),
      );
      expect(summary, isNotNull);
      expect(summary!.material, equals(CatheterMaterial.silicone30Day));
      expect(summary.totalLifespanDays, equals(30));
      expect(summary.bagEmptyingIntervalHours, equals(6));
      expect(summary.nextBagEmptyingDue!.isAtSameMomentAs(insertionDate.add(const Duration(hours: 6))), isTrue);
      expect(summary.isBagEmptyingDue, isFalse);
    });

    test('Records catheter with custom lifespan days (e.g. 21 days)', () async {
      final insertionDate = DateTime.utc(2026, 9, 1, 8, 0);

      final catheter = await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: insertionDate,
        material: CatheterMaterial.custom,
        customLifespanDays: 21,
      );

      expect(catheter.material, equals('custom'));
      expect(catheter.lifespanDays, equals(21));
      expect(catheter.replacementDueDate.isAtSameMomentAs(insertionDate.add(const Duration(days: 21))), isTrue);
    });

    test('1-tap recordBagEmptied documents evacuated volume and Hematuria Grade in a single unified step', () async {
      final insertionDate = DateTime.utc(2026, 9, 1, 8, 0);
      await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: insertionDate,
        material: CatheterMaterial.latex14Day,
        bagEmptyingIntervalHours: 4,
      );

      // Verify before emptying: next due is 8:00 + 4h = 12:00
      final summaryBefore = await repository.getCatheterLifespanSummary(
        patientId,
        asOf: DateTime.utc(2026, 9, 1, 9, 0),
      );
      expect(summaryBefore!.lastBagEmptiedAt, isNull);
      expect(summaryBefore.nextBagEmptyingDue!.isAtSameMomentAs(DateTime.utc(2026, 9, 1, 12, 0)), isTrue);

      // Perform 1-tap "Bag Emptied" recording action at 12:00
      final emptyTime = DateTime.utc(2026, 9, 1, 12, 0);
      final result = await repository.recordBagEmptied(
        patientId: patientId,
        volumeMl: 550,
        hematuriaGrade: 2,
        recordedAt: emptyTime,
      );

      // Verify FluidOutputLog was created with correct attributes
      expect(result.outputLog.patientId, equals(patientId));
      expect(result.outputLog.volumeMl, equals(550));
      expect(result.outputLog.hematuriaGrade, equals(2));
      expect(result.outputLog.outputType, equals('urine'));
      expect(result.outputLog.recordedAt.isAtSameMomentAs(emptyTime), isTrue);

      // Verify active catheter record updated lastBagEmptiedAt
      expect(result.catheter.lastBagEmptiedAt!.isAtSameMomentAs(emptyTime), isTrue);

      // Verify updated summary reflects new schedule (next due is 12:00 + 4h = 16:00)
      final summaryAfter = await repository.getCatheterLifespanSummary(
        patientId,
        asOf: DateTime.utc(2026, 9, 1, 13, 0),
      );
      expect(summaryAfter!.lastBagEmptiedAt!.isAtSameMomentAs(emptyTime), isTrue);
      expect(summaryAfter.nextBagEmptyingDue!.isAtSameMomentAs(DateTime.utc(2026, 9, 1, 16, 0)), isTrue);
      expect(summaryAfter.isBagEmptyingDue, isFalse);
      expect(summaryAfter.minutesUntilNextBagEmptying, equals(180));
    });

    test('recordBagEmptied validates volume and Hematuria Grade constraints', () async {
      await repository.recordCatheterInsertion(
        patientId: patientId,
        insertionDate: DateTime.utc(2026, 9, 1, 8, 0),
      );

      // Invalid volume
      expect(
        () => repository.recordBagEmptied(
          patientId: patientId,
          volumeMl: 0,
          hematuriaGrade: 1,
        ),
        throwsArgumentError,
      );

      // Invalid Hematuria grade (< 1 or > 4)
      expect(
        () => repository.recordBagEmptied(
          patientId: patientId,
          volumeMl: 300,
          hematuriaGrade: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => repository.recordBagEmptied(
          patientId: patientId,
          volumeMl: 300,
          hematuriaGrade: 5,
        ),
        throwsArgumentError,
      );
    });
  });
}
