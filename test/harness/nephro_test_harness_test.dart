import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/domain/vascular_safety_rules.dart';
import 'package:nephrocare/src/features/catheter/domain/catheter_lifespan_rules.dart';
import 'package:nephrocare/src/features/dialysis/domain/hemodialysis_calculation_rules.dart';
import 'package:nephrocare/src/features/fluid/domain/fluid_balance_summary.dart';

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

    test('Top-level test harness verifies calculation accuracy and inspection validation across sequential sessions', () async {
      // 1. Establish Patient on Hemodialysis with Prescribed Dry Weight
      final patient = await harness.createPatient(
        name: 'David Bowman',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 70.0,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
      );

      final session1StartTime = DateTime.now().subtract(const Duration(days: 2));

      // 2. Session 1 Pre-Dialysis Check-in (First session: IDWG calculated against Prescribed Dry Weight)
      // Pre-weight: 72.8 kg -> IDWG = 72.8 - 70.0 = 2.8 kg
      // UF Goal with 300 mL allowance = (2.8 * 1000) + 300 = 3100 mL
      final session1 = await harness.recordPreDialysisCheckIn(
        patientId: patient.id,
        preWeightKg: 72.8,
        volumeAllowanceMl: 300,
        thrillPresent: true,
        bruitPresent: true,
        startedAt: session1StartTime,
      );

      expect(session1.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(session1.id),
        isTrue,
      );
      expect(session1.calculatedInterdialyticWeightGainKg, equals(2.8));
      expect(session1.calculatedUltrafiltrationGoalMl, equals(3100));

      // Verify Access Inspection persistence for Session 1
      final inspections1 = await harness.getAccessInspections(patient.id);
      expect(inspections1.length, equals(1));
      expect(inspections1.first.thrillPresent, isTrue);
      expect(inspections1.first.bruitPresent, isTrue);

      // 3. Complete Session 1 with post-weight and cramping symptom
      // Post-weight 70.1 kg -> difference from Prescribed Dry Weight: 70.1 - 70.0 = +0.1 kg
      final completedSession1 = await harness.recordPostDialysisSession(
        sessionId: session1.id,
        postWeightKg: 70.1,
        actualFluidRemovedMl: 3000,
        symptoms: ['cramping'],
        endedAt: session1StartTime.add(const Duration(hours: 4)),
      );

      expect(completedSession1.postWeightKg, equals(70.1));
      expect(completedSession1.calculatedPostWeightDifferenceKg, equals(0.1));
      expect(completedSession1.symptoms, contains('cramping'));
      expect(completedSession1.endedAt, isNotNull);

      // 4. Session 2 Pre-Dialysis Check-in (Sequential session: IDWG calculated against Session 1 post-weight)
      // Pre-weight: 73.0 kg -> IDWG = 73.0 - 70.1 = 2.9 kg
      // UF Goal with 200 mL allowance = ((73.0 - 70.0) * 1000) + 200 = 3200 mL
      final session2StartTime = DateTime.now();
      final session2 = await harness.recordPreDialysisCheckIn(
        patientId: patient.id,
        preWeightKg: 73.0,
        volumeAllowanceMl: 200,
        thrillPresent: true,
        bruitPresent: true,
        startedAt: session2StartTime,
      );

      expect(session2.calculatedInterdialyticWeightGainKg, equals(2.9));
      expect(session2.calculatedUltrafiltrationGoalMl, equals(3200));

      // Verify Access Inspection persistence across sequential sessions
      final inspections2 = await harness.getAccessInspections(patient.id);
      expect(inspections2.length, equals(2));
      expect(inspections2[0].thrillPresent, isTrue);
      expect(inspections2[0].bruitPresent, isTrue);

      // 5. Complete Session 2 with post-weight and hypotension/dizziness symptoms
      // Post-weight 69.8 kg -> difference from Prescribed Dry Weight: 69.8 - 70.0 = -0.2 kg
      final completedSession2 = await harness.recordPostDialysisSession(
        sessionId: session2.id,
        postWeightKg: 69.8,
        actualFluidRemovedMl: 3200,
        symptoms: ['dizziness', 'hypotension'],
        endedAt: session2StartTime.add(const Duration(hours: 4)),
      );

      expect(completedSession2.postWeightKg, equals(69.8));
      expect(completedSession2.calculatedPostWeightDifferenceKg, equals(-0.2));
      expect(completedSession2.symptoms, contains('dizziness'));
      expect(completedSession2.symptoms, contains('hypotension'));

      // 6. Verify sequential sessions history order (most recent first)
      final allSessions = await harness.getDialysisSessions(patient.id);
      expect(allSessions.length, equals(2));
      expect(allSessions[0].id, equals(session2.id));
      expect(allSessions[1].id, equals(session1.id));

      // 7. Verify access inspection validation rules for fistula and central lines
      final fistulaWarnings = HemodialysisCalculationRules.getAccessSafetyWarnings(
        accessType: 'arteriovenousFistula',
        thrillPresent: false,
        bruitPresent: true,
      );
      expect(fistulaWarnings, contains('Absent thrill detected in vascular fistula/graft.'));

      final centralLineWarnings = HemodialysisCalculationRules.getAccessSafetyWarnings(
        accessType: 'dialysisCentralLine',
        rednessPresent: true,
        swellingPresent: true,
        dischargePresent: true,
        painPresent: true,
      );
      expect(centralLineWarnings.length, equals(4));
      expect(centralLineWarnings, contains('Exit-site redness detected.'));
      expect(centralLineWarnings, contains('Exit-site swelling detected.'));
      expect(centralLineWarnings, contains('Exit-site discharge detected.'));
      expect(centralLineWarnings, contains('Exit-site pain reported.'));
    });

    test('Top-level test harness verifies 24-hour Fluid Balance calculation and Phosphate Binder reminder associations', () async {
      final now = DateTime.now().toUtc();

      // 1. Establish Patient on Hemodialysis with prescribed daily Fluid Allowance
      final patient = await harness.createPatient(
        name: 'Arthur Dent',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1500,
        prescribedDryWeightKg: 74.0,
      );

      // 2. Initial state: 0 intake, 0 output, 0 balance
      final initialBalance = await harness.get24HourFluidBalance(patient.id, asOf: now);
      expect(initialBalance.totalIntakeMl, equals(0));
      expect(initialBalance.totalOutputMl, equals(0));
      expect(initialBalance.netBalanceMl, equals(0));
      expect(initialBalance.dailyFluidAllowanceMl, equals(1500));
      expect(initialBalance.remainingAllowanceMl, equals(1500));
      expect(initialBalance.allowanceStatus, equals(FluidAllowanceStatus.withinLimit));

      // 3. Log morning intake: 250 mL Water without binder
      final morningIntake = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 250,
        beverageType: 'Water',
        phosphateBinderTaken: false,
        recordedAt: now.subtract(const Duration(hours: 6)),
      );
      expect(morningIntake.id, isNotEmpty);
      expect(morningIntake.phosphateBinderTaken, isFalse);

      // 4. Log lunch fluid/meal intake: 500 mL Soup WITH Phosphate Binder taken per CONTEXT.md
      final lunchIntake = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 500,
        beverageType: 'Soup / Broth',
        phosphateBinderTaken: true,
        recordedAt: now.subtract(const Duration(hours: 4)),
      );
      expect(lunchIntake.id, isNotEmpty);
      expect(lunchIntake.phosphateBinderTaken, isTrue);

      // 5. Log afternoon tea preset: 150 mL Tea
      final teaIntake = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 150,
        beverageType: 'Tea',
        phosphateBinderTaken: false,
        recordedAt: now.subtract(const Duration(hours: 2)),
      );
      expect(teaIntake.id, isNotEmpty);

      // 6. Verify cumulative intake progression (250 + 500 + 150 = 900 mL / 1500 mL = 60.0%)
      final intermediateBalance = await harness.get24HourFluidBalance(patient.id, asOf: now);
      expect(intermediateBalance.totalIntakeMl, equals(900));
      expect(intermediateBalance.intakePercentageOfAllowance, equals(60.0));
      expect(intermediateBalance.remainingAllowanceMl, equals(600));
      expect(intermediateBalance.allowanceStatus, equals(FluidAllowanceStatus.withinLimit));

      // 7. Verify Phosphate Binder reminder associations
      final intakeLogs = await harness.getFluidIntakeLogs(patient.id);
      expect(intakeLogs.length, equals(3));
      final logsWithBinder = intakeLogs.where((l) => l.phosphateBinderTaken).toList();
      expect(logsWithBinder.length, equals(1));
      expect(logsWithBinder.first.id, equals(lunchIntake.id));
      expect(logsWithBinder.first.beverageType, equals('Soup / Broth'));

      // 8. Log fluid output: Urine evacuation (350 mL, Hematuria Grade 1) and Ultrafiltration (250 mL)
      final urineOutput = await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 350,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: now.subtract(const Duration(hours: 3)),
      );
      expect(urineOutput.id, isNotEmpty);
      expect(urineOutput.hematuriaGrade, equals(1));

      final ufOutput = await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 250,
        outputType: 'ultrafiltration',
        recordedAt: now.subtract(const Duration(hours: 1)),
      );
      expect(ufOutput.id, isNotEmpty);

      // 9. Verify 24-hour net Fluid Balance:
      // Total Intake: 900 mL
      // Total Output: 350 + 250 = 600 mL
      // Net Fluid Balance: 900 - 600 = +300 mL (surplus)
      final netBalance = await harness.get24HourFluidBalance(patient.id, asOf: now);
      expect(netBalance.totalIntakeMl, equals(900));
      expect(netBalance.totalOutputMl, equals(600));
      expect(netBalance.netBalanceMl, equals(300));
      expect(netBalance.remainingAllowanceMl, equals(600));

      // 10. Verify allowance progression transitions:
      // Add 400 mL intake -> 1300 mL / 1500 mL = 86.7% (nearingLimit)
      await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 400,
        beverageType: 'Water',
        recordedAt: now.subtract(const Duration(minutes: 30)),
      );
      final nearingBalance = await harness.get24HourFluidBalance(patient.id, asOf: now);
      expect(nearingBalance.totalIntakeMl, equals(1300));
      expect(nearingBalance.intakePercentageOfAllowance, equals(86.7));
      expect(nearingBalance.remainingAllowanceMl, equals(200));
      expect(nearingBalance.allowanceStatus, equals(FluidAllowanceStatus.nearingLimit));

      // Add 300 mL intake -> 1600 mL / 1500 mL = 106.7% (exceeded, 0 remaining)
      await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 300,
        beverageType: 'Juice',
        recordedAt: now,
      );
      final exceededBalance = await harness.get24HourFluidBalance(patient.id, asOf: now);
      expect(exceededBalance.totalIntakeMl, equals(1600));
      expect(exceededBalance.intakePercentageOfAllowance, equals(106.7));
      expect(exceededBalance.remainingAllowanceMl, equals(0));
      expect(exceededBalance.allowanceStatus, equals(FluidAllowanceStatus.exceeded));
      // Net balance: 1600 - 600 = +1000 mL
      expect(exceededBalance.netBalanceMl, equals(1000));
    });

    test('Top-level test harness verifies state transitions across the 14-day lifespan cycle and CAUTI Risk Window triggering', () async {
      // 1. Establish Patient under indwelling Urine Foley Catheter clinical care
      final patient = await harness.createPatient(
        name: 'George Washington',
        diagnosis: 'urologicalCatheter',
        dailyFluidAllowanceMl: 2000,
      );
      expect(patient.id, isNotEmpty);
      expect(patient.diagnosis, equals('urologicalCatheter'));

      final insertionDate = DateTime.utc(2026, 9, 1, 8, 0);

      // 2. Record initial Urine Foley Catheter insertion event
      final initialCatheter = await harness.recordCatheterInsertion(
        patientId: patient.id,
        insertionDate: insertionDate,
        notes: 'Initial insertion of 16 Fr indwelling Foley catheter.',
      );

      expect(initialCatheter.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(initialCatheter.id),
        isTrue,
      );
      expect(initialCatheter.catheterType, equals('foley'));
      expect(initialCatheter.status, equals('active'));
      expect(initialCatheter.insertionDate.isAtSameMomentAs(insertionDate), isTrue);
      expect(initialCatheter.replacementDueDate.isAtSameMomentAs(insertionDate.add(const Duration(days: 14))), isTrue);
      expect(initialCatheter.createdAt, isNotNull);
      expect(initialCatheter.updatedAt, isNotNull);

      // 3. Verify state transition: Green state for Days 1 to 10
      // Day 1:
      final evalDay1 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 1, 12, 0),
      );
      expect(evalDay1, isNotNull);
      expect(evalDay1!.status, equals(CatheterLifespanStatus.green));
      expect(evalDay1.dayOfCycle, equals(1));
      expect(evalDay1.daysElapsed, equals(0));
      expect(evalDay1.daysRemaining, equals(14));
      expect(evalDay1.isCautiRiskActive, isFalse);

      // Day 6:
      final evalDay6 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 6, 8, 0),
      );
      expect(evalDay6!.status, equals(CatheterLifespanStatus.green));
      expect(evalDay6.dayOfCycle, equals(6));
      expect(evalDay6.daysElapsed, equals(5));
      expect(evalDay6.daysRemaining, equals(9));
      expect(evalDay6.isCautiRiskActive, isFalse);

      // Day 10 (Last day of green window):
      final evalDay10 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 10, 23, 0),
      );
      expect(evalDay10!.status, equals(CatheterLifespanStatus.green));
      expect(evalDay10.dayOfCycle, equals(10));
      expect(evalDay10.daysElapsed, equals(9));
      expect(evalDay10.daysRemaining, equals(5));
      expect(evalDay10.isCautiRiskActive, isFalse);

      // 4. Verify state transition: Amber state for Days 11 to 14 (Mandatory replacement approaching)
      // Day 11 (First day of amber warning):
      final evalDay11 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 11, 8, 0),
      );
      expect(evalDay11!.status, equals(CatheterLifespanStatus.amber));
      expect(evalDay11.dayOfCycle, equals(11));
      expect(evalDay11.daysElapsed, equals(10));
      expect(evalDay11.daysRemaining, equals(4));
      expect(evalDay11.isCautiRiskActive, isFalse);

      // Day 14 (14-day due date):
      final evalDay14 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 14, 20, 0),
      );
      expect(evalDay14!.status, equals(CatheterLifespanStatus.amber));
      expect(evalDay14.dayOfCycle, equals(14));
      expect(evalDay14.daysElapsed, equals(13));
      expect(evalDay14.daysRemaining, equals(1));
      expect(evalDay14.isCautiRiskActive, isFalse);

      // 5. Verify state transition: Red state for Days 15+ (CAUTI Risk Window Triggered!)
      // Day 15:
      final evalDay15 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 15, 8, 0),
      );
      expect(evalDay15!.status, equals(CatheterLifespanStatus.red));
      expect(evalDay15.dayOfCycle, equals(15));
      expect(evalDay15.daysElapsed, equals(14));
      expect(evalDay15.daysRemaining, equals(0));
      expect(evalDay15.daysOverdue, equals(1));
      expect(evalDay15.isCautiRiskActive, isTrue);

      // Day 18 (4 days overdue in CAUTI risk window):
      final evalDay18 = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: DateTime.utc(2026, 9, 18, 8, 0),
      );
      expect(evalDay18!.status, equals(CatheterLifespanStatus.red));
      expect(evalDay18.dayOfCycle, equals(18));
      expect(evalDay18.daysElapsed, equals(17));
      expect(evalDay18.daysRemaining, equals(0));
      expect(evalDay18.daysOverdue, equals(4));
      expect(evalDay18.isCautiRiskActive, isTrue);

      // 6. Record Urine Evacuation with Standardized Hematuria Grading during CAUTI Risk Window
      final urineLog = await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 450,
        outputType: 'urine',
        hematuriaGrade: 3, // Grade 3: Red/Gross
        recordedAt: DateTime.utc(2026, 9, 18, 8, 30),
      );

      expect(urineLog.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(urineLog.id),
        isTrue,
      );
      expect(urineLog.outputType, equals('urine'));
      expect(urineLog.volumeMl, equals(450));
      expect(urineLog.hematuriaGrade, equals(3));
      expect(HematuriaGradeInfo.fromGrade(urineLog.hematuriaGrade!).title, equals('Grade 3: Red/Gross'));
      expect(urineLog.createdAt, isNotNull);
      expect(urineLog.updatedAt, isNotNull);

      // 7. Catheter Replacement Event resets the 14-day cycle and retires the previous catheter
      final replacementDate = DateTime.utc(2026, 9, 18, 9, 0);
      final replacedCatheter = await harness.recordCatheterReplacement(
        patientId: patient.id,
        replacementDate: replacementDate,
        notes: 'Clinical exchange: replaced due to Day 18 CAUTI risk window and Grade 3 hematuria.',
      );

      expect(replacedCatheter.id, isNot(equals(initialCatheter.id)));
      expect(replacedCatheter.status, equals('active'));
      expect(replacedCatheter.insertionDate.isAtSameMomentAs(replacementDate), isTrue);
      expect(replacedCatheter.replacementDueDate.isAtSameMomentAs(replacementDate.add(const Duration(days: 14))), isTrue);

      // Verify previous catheter was marked replaced in Drift SQLite
      final history = await harness.getCatheterHistory(patient.id);
      expect(history.length, equals(2));
      final oldCatheterInDb = history.firstWhere((e) => e.id == initialCatheter.id);
      expect(oldCatheterInDb.status, equals('replaced'));
      expect(oldCatheterInDb.updatedAt, isNotNull);

      // Verify active catheter is now reset to Day 1 (Green status, 14 days remaining)
      final evalPostReplacement = await harness.evaluateCatheterLifespan(
        patient.id,
        asOf: replacementDate,
      );
      expect(evalPostReplacement!.status, equals(CatheterLifespanStatus.green));
      expect(evalPostReplacement.dayOfCycle, equals(1));
      expect(evalPostReplacement.daysElapsed, equals(0));
      expect(evalPostReplacement.daysRemaining, equals(14));
      expect(evalPostReplacement.isCautiRiskActive, isFalse);
    });
  });
}
