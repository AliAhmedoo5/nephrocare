import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/app_database.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/fluid/data/fluid_repository.dart';
import 'package:nephrocare/src/features/fluid/domain/fluid_balance_summary.dart';

void main() {
  group('Unified Application & State Seam: Fluid Repository & Persistence', () {
    late NephroTestHarness harness;
    late FluidRepository fluidRepo;
    late Patient testPatient;

    setUp(() async {
      harness = createNephroTestHarness();
      fluidRepo = FluidRepository(harness.database);
      testPatient = await harness.createPatient(
        name: 'Martha Stewart',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1500,
        prescribedDryWeightKg: 62.0,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('recordFluidIntake validates patient, assigns UUIDv4, and persists intake log with binder metadata', () async {
      final now = DateTime.now().toUtc();
      final intake = await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 250,
        beverageType: 'Water',
        phosphateBinderTaken: true,
        recordedAt: now,
      );

      expect(intake.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(intake.id),
        isTrue,
      );
      expect(intake.patientId, equals(testPatient.id));
      expect(intake.volumeMl, equals(250));
      expect(intake.beverageType, equals('Water'));
      expect(intake.phosphateBinderTaken, isTrue);
      expect(intake.createdAt, isNotNull);
      expect(intake.updatedAt, isNotNull);

      final dbLogs = await fluidRepo.getFluidIntakeLogs(testPatient.id);
      expect(dbLogs.length, equals(1));
      expect(dbLogs.first.id, equals(intake.id));
    });

    test('recordFluidIntake throws ArgumentError for unknown patient', () async {
      expect(
        () => fluidRepo.recordFluidIntake(
          patientId: 'unknown-uuid',
          volumeMl: 200,
          beverageType: 'Tea',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('recordFluidOutput persists output volume and validates hematuria grade range (1..4)', () async {
      final now = DateTime.now().toUtc();
      final output = await fluidRepo.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 350,
        outputType: 'urine',
        hematuriaGrade: 2,
        recordedAt: now,
      );

      expect(output.id, isNotEmpty);
      expect(output.volumeMl, equals(350));
      expect(output.outputType, equals('urine'));
      expect(output.hematuriaGrade, equals(2));

      // Invalid hematuria grade (e.g. 5) must throw ArgumentError
      expect(
        () => fluidRepo.recordFluidOutput(
          patientId: testPatient.id,
          volumeMl: 200,
          outputType: 'urine',
          hematuriaGrade: 5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('get24HourFluidBalance calculates net balance and progression strictly within 24-hour window', () async {
      final now = DateTime.now().toUtc();

      // Recent intake (within 24h)
      await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 300,
        beverageType: 'Water',
        phosphateBinderTaken: false,
        recordedAt: now.subtract(const Duration(hours: 2)),
      );
      await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 450,
        beverageType: 'Soup',
        phosphateBinderTaken: true,
        recordedAt: now.subtract(const Duration(hours: 5)),
      );

      // Old intake (> 24h ago, must NOT be included in 24h balance)
      await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 500,
        beverageType: 'Tea',
        recordedAt: now.subtract(const Duration(hours: 26)),
      );

      // Recent output (within 24h)
      await fluidRepo.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 200,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: now.subtract(const Duration(hours: 3)),
      );
      await fluidRepo.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 150,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: now.subtract(const Duration(hours: 1)),
      );

      // Old output (> 24h ago, must NOT be included)
      await fluidRepo.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 400,
        outputType: 'urine',
        recordedAt: now.subtract(const Duration(hours: 28)),
      );

      final balance = await fluidRepo.get24HourFluidBalance(testPatient.id, asOf: now);

      // Intake: 300 + 450 = 750 mL
      expect(balance.totalIntakeMl, equals(750));
      // Output: 200 + 150 = 350 mL
      expect(balance.totalOutputMl, equals(350));
      // Net balance: 750 - 350 = +400 mL
      expect(balance.netBalanceMl, equals(400));
      // Allowance: 1500 mL -> 750 / 1500 = 50.0%
      expect(balance.intakePercentageOfAllowance, equals(50.0));
      expect(balance.remainingAllowanceMl, equals(750));
      expect(balance.allowanceStatus, equals(FluidAllowanceStatus.withinLimit));
    });

    test('watch24HourFluidBalance emits real-time updates as intake and output are logged', () async {
      final stream = fluidRepo.watch24HourFluidBalance(testPatient.id);

      final initial = await stream.first;
      expect(initial.totalIntakeMl, equals(0));
      expect(initial.totalOutputMl, equals(0));
      expect(initial.netBalanceMl, equals(0));

      // Record intake and verify stream reflects new balance
      await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 250,
        beverageType: 'Coffee',
        phosphateBinderTaken: true,
      );

      final updatedIntake = await fluidRepo.watch24HourFluidBalance(testPatient.id).first;
      expect(updatedIntake.totalIntakeMl, equals(250));
      expect(updatedIntake.netBalanceMl, equals(250));

      // Record output and verify stream reflects updated net balance
      await fluidRepo.recordFluidOutput(
        patientId: testPatient.id,
        volumeMl: 100,
        outputType: 'urine',
      );

      final updatedOutput = await fluidRepo.watch24HourFluidBalance(testPatient.id).first;
      expect(updatedOutput.totalIntakeMl, equals(250));
      expect(updatedOutput.totalOutputMl, equals(100));
      expect(updatedOutput.netBalanceMl, equals(150));
    });

    test('updateFluidIntake modifies intake entry and recalculates 24-hour Fluid Balance', () async {
      final now = DateTime.now().toUtc();
      final intake = await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 500,
        beverageType: 'Water',
        recordedAt: now,
      );

      var balance = await fluidRepo.get24HourFluidBalance(testPatient.id, asOf: now);
      expect(balance.totalIntakeMl, equals(500));

      final updated = await fluidRepo.updateFluidIntake(
        id: intake.id,
        volumeMl: 250,
        beverageType: 'Tea',
        phosphateBinderTaken: true,
      );

      expect(updated.id, equals(intake.id));
      expect(updated.volumeMl, equals(250));
      expect(updated.beverageType, equals('Tea'));
      expect(updated.phosphateBinderTaken, isTrue);

      balance = await fluidRepo.get24HourFluidBalance(testPatient.id, asOf: now);
      expect(balance.totalIntakeMl, equals(250));
    });

    test('deleteFluidIntake removes intake entry and restores 24-hour Fluid Balance', () async {
      final now = DateTime.now().toUtc();
      final intake = await fluidRepo.recordFluidIntake(
        patientId: testPatient.id,
        volumeMl: 350,
        beverageType: 'Juice',
        recordedAt: now,
      );

      var balance = await fluidRepo.get24HourFluidBalance(testPatient.id, asOf: now);
      expect(balance.totalIntakeMl, equals(350));

      await fluidRepo.deleteFluidIntake(intake.id);

      final logs = await fluidRepo.getFluidIntakeLogs(testPatient.id);
      expect(logs.any((l) => l.id == intake.id), isFalse);

      balance = await fluidRepo.get24HourFluidBalance(testPatient.id, asOf: now);
      expect(balance.totalIntakeMl, equals(0));
    });
  });
}
