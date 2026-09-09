import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/domain/vascular_safety_rules.dart';
import 'package:nephrocare/src/features/catheter/domain/catheter_lifespan_rules.dart';
import 'package:nephrocare/src/features/dialysis/domain/hemodialysis_calculation_rules.dart';
import 'package:nephrocare/src/features/fluid/domain/fluid_balance_summary.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';
import 'package:nephrocare/src/features/reports/domain/clinical_report_config.dart';

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

    test('Top-level test harness verifies strict data segregation across multiple patient profiles and seamless Caregiver Mirror switching', () async {
      final now = DateTime.now().toUtc();

      // 1. Establish Patient 1: Direct Patient on Hemodialysis
      final patient1 = await harness.createPatient(
        name: 'Eleanor Vance',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 68.0,
        dailyFluidAllowanceMl: 1200,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        isCaregiverMirror: false,
      );

      // 2. Establish Patient 2: Caregiver Mirror profile for Urological Catheter dependent
      final patient2 = await harness.createPatient(
        name: 'Grandpa Joe',
        diagnosis: 'urologicalCatheter',
        dailyFluidAllowanceMl: 2000,
        isCaregiverMirror: true,
      );

      // Verify profile types
      expect(patient1.isCaregiverMirror, isFalse);
      expect(patient2.isCaregiverMirror, isTrue);

      // 3. Record clinical data for Patient 1 (Hemodialysis)
      final p1Session = await harness.recordPreDialysisCheckIn(
        patientId: patient1.id,
        preWeightKg: 70.2,
        volumeAllowanceMl: 200,
        thrillPresent: true,
        bruitPresent: true,
        startedAt: now.subtract(const Duration(hours: 3)),
      );
      expect(p1Session.id, isNotEmpty);

      final p1Bp = await harness.recordBloodPressure(
        patientId: patient1.id,
        systolic: 130,
        diastolic: 80,
        pulse: 72,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(hours: 2)),
      );
      expect(p1Bp.id, isNotEmpty);

      await harness.recordFluidIntake(
        patientId: patient1.id,
        volumeMl: 300,
        beverageType: 'Water',
        recordedAt: now.subtract(const Duration(hours: 2)),
      );

      await harness.recordFluidOutput(
        patientId: patient1.id,
        volumeMl: 200,
        outputType: 'urine',
        recordedAt: now.subtract(const Duration(hours: 1)),
      );

      // 4. Record clinical data for Patient 2 (Caregiver Mirror, Foley Catheter)
      final p2Catheter = await harness.recordCatheterInsertion(
        patientId: patient2.id,
        insertionDate: now.subtract(const Duration(days: 3)),
        notes: 'Grandpa Joe catheter monitored by caregiver',
      );
      expect(p2Catheter.id, isNotEmpty);

      final p2Bp = await harness.recordBloodPressure(
        patientId: patient2.id,
        systolic: 145,
        diastolic: 90,
        pulse: 78,
        armUsed: 'leftArm',
        recordedAt: now.subtract(const Duration(hours: 2)),
      );
      expect(p2Bp.id, isNotEmpty);

      await harness.recordFluidIntake(
        patientId: patient2.id,
        volumeMl: 500,
        beverageType: 'Water',
        recordedAt: now.subtract(const Duration(hours: 2)),
      );

      await harness.recordFluidOutput(
        patientId: patient2.id,
        volumeMl: 600,
        outputType: 'urine',
        hematuriaGrade: 2,
        recordedAt: now.subtract(const Duration(hours: 1)),
      );

      // 5. Verify strict database isolation & segregation per Patient ID
      // Blood Pressure isolation:
      final p1BpTrends = await harness.getHemodynamicTrends(patient1.id);
      expect(p1BpTrends.length, equals(1));
      expect(p1BpTrends.first.id, equals(p1Bp.id));
      expect(p1BpTrends.first.systolic, equals(130));
      expect(p1BpTrends.first.armUsed, equals('rightArm'));

      final p2BpTrends = await harness.getHemodynamicTrends(patient2.id);
      expect(p2BpTrends.length, equals(1));
      expect(p2BpTrends.first.id, equals(p2Bp.id));
      expect(p2BpTrends.first.systolic, equals(145));
      expect(p2BpTrends.first.armUsed, equals('leftArm'));

      // Dialysis Sessions isolation:
      final p1Sessions = await harness.getDialysisSessions(patient1.id);
      expect(p1Sessions.length, equals(1));
      expect(p1Sessions.first.patientId, equals(patient1.id));

      final p2Sessions = await harness.getDialysisSessions(patient2.id);
      expect(p2Sessions, isEmpty); // Patient 2 has zero dialysis sessions

      // Catheter Events isolation:
      final p1ActiveCatheter = await harness.getActiveCatheter(patient1.id);
      expect(p1ActiveCatheter, isNull); // Patient 1 has no catheter events

      final p2ActiveCatheter = await harness.getActiveCatheter(patient2.id);
      expect(p2ActiveCatheter, isNotNull);
      expect(p2ActiveCatheter!.id, equals(p2Catheter.id));
      expect(p2ActiveCatheter.patientId, equals(patient2.id));

      // 24-Hour Fluid Balance isolation:
      final p1Balance = await harness.get24HourFluidBalance(patient1.id, asOf: now);
      expect(p1Balance.totalIntakeMl, equals(300));
      expect(p1Balance.totalOutputMl, equals(200));
      expect(p1Balance.netBalanceMl, equals(100));
      expect(p1Balance.dailyFluidAllowanceMl, equals(1200));

      final p2Balance = await harness.get24HourFluidBalance(patient2.id, asOf: now);
      expect(p2Balance.totalIntakeMl, equals(500));
      expect(p2Balance.totalOutputMl, equals(600));
      expect(p2Balance.netBalanceMl, equals(-100));
      expect(p2Balance.dailyFluidAllowanceMl, equals(2000));

      // 6. Seamless Profile Switching via harness
      await harness.switchActivePatient(patient1.id, asOf: now.subtract(const Duration(seconds: 2)));
      final active1 = await harness.getActivePatient();
      expect(active1, isNotNull);
      expect(active1!.id, equals(patient1.id));
      expect(active1.name, equals('Eleanor Vance'));
      expect(active1.isCaregiverMirror, isFalse);

      await harness.switchActivePatient(patient2.id, asOf: now);
      final active2 = await harness.getActivePatient();
      expect(active2, isNotNull);
      expect(active2!.id, equals(patient2.id));
      expect(active2.name, equals('Grandpa Joe'));
      expect(active2.isCaregiverMirror, isTrue);
    });

    test('Document generation test harness verifies that selected modules and date filtering reflect accurately in the compiled PDF document structure', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0);

      // 1. Establish Patient on Hemodialysis
      final patient = await harness.createPatient(
        name: 'Sarah Connor',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 62.0,
        dailyFluidAllowanceMl: 1400,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        isCaregiverMirror: false,
      );

      // 2. Populate longitudinal clinical dataset across 30 days
      // Dialysis session 3 days ago (within 7d, 14d, 30d)
      final sessionRecent = await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 3)),
        preWeightKg: 64.2,
        postWeightKg: 62.1,
        calculatedInterdialyticWeightGainKg: 2.2,
        calculatedUltrafiltrationGoalMl: 2200,
        calculatedPostWeightDifferenceKg: 0.1,
        actualFluidRemovedMl: 2100,
      );

      // Dialysis session 10 days ago (within 14d and 30d, but outside 7d)
      final sessionMedium = await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 10)),
        preWeightKg: 64.5,
        postWeightKg: 62.0,
        calculatedInterdialyticWeightGainKg: 2.5,
        calculatedUltrafiltrationGoalMl: 2500,
        calculatedPostWeightDifferenceKg: 0.0,
        actualFluidRemovedMl: 2400,
      );

      // Dialysis session 22 days ago (within 30d, but outside 7d and 14d)
      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 22)),
        preWeightKg: 65.0,
        postWeightKg: 62.2,
      );

      // Blood pressure logs: 1d ago, 12d ago, 25d ago
      final bpRecent = await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 122,
        diastolic: 78,
        pulse: 70,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 1)),
      );
      final bpMedium = await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 130,
        diastolic: 84,
        pulse: 76,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 12)),
      );
      await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 138,
        diastolic: 88,
        pulse: 82,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 25)),
      );

      // Access inspection & catheter events
      await harness.recordAccessInspection(
        patientId: patient.id,
        accessType: 'arteriovenousFistula',
        anatomicalLocation: 'leftArm',
        thrillPresent: true,
        bruitPresent: true,
        recordedAt: now.subtract(const Duration(days: 3)),
      );
      await harness.recordCatheterInsertion(
        patientId: patient.id,
        insertionDate: now.subtract(const Duration(days: 5)),
        notes: 'Clinical catheter event',
      );

      // 3. Test 7-Day Window Filter
      final config7d = ModularReportConfig(
        dateWindow: ReportDateWindow.last7Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.weightTrends,
          ClinicalReportModule.bloodPressureAndPulse,
        },
      );
      final data7d = await harness.compileModularClinicalReportData(
        patientId: patient.id,
        config: config7d,
        asOf: now,
      );
      expect(data7d.dialysisSessions.length, equals(1));
      expect(data7d.dialysisSessions.first.id, equals(sessionRecent.id));
      expect(data7d.bloodPressureLogs.length, equals(1));
      expect(data7d.bloodPressureLogs.first.id, equals(bpRecent.id));

      final pdf7dBytes = await harness.generateModularClinicalReportPdf(
        patientId: patient.id,
        config: config7d,
        asOf: now,
      );
      expect(pdf7dBytes, isNotEmpty);
      expect(utf8.decode(pdf7dBytes.sublist(0, 5)), equals('%PDF-'));

      // 4. Test 14-Day Window Filter
      final config14d = ModularReportConfig(
        dateWindow: ReportDateWindow.last14Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.weightTrends,
          ClinicalReportModule.bloodPressureAndPulse,
        },
      );
      final data14d = await harness.compileModularClinicalReportData(
        patientId: patient.id,
        config: config14d,
        asOf: now,
      );
      expect(data14d.dialysisSessions.length, equals(2));
      expect(data14d.dialysisSessions.map((s) => s.id), containsAll([sessionRecent.id, sessionMedium.id]));
      expect(data14d.bloodPressureLogs.length, equals(2));
      expect(data14d.bloodPressureLogs.map((b) => b.id), containsAll([bpRecent.id, bpMedium.id]));

      // 5. Test 30-Day Window Filter
      final config30d = ModularReportConfig(
        dateWindow: ReportDateWindow.last30Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.weightTrends,
          ClinicalReportModule.bloodPressureAndPulse,
        },
      );
      final data30d = await harness.compileModularClinicalReportData(
        patientId: patient.id,
        config: config30d,
        asOf: now,
      );
      expect(data30d.dialysisSessions.length, equals(3));
      expect(data30d.bloodPressureLogs.length, equals(3));

      // 6. Test Selective Module Inclusion/Exclusion
      final configSelective = ModularReportConfig(
        dateWindow: ReportDateWindow.last30Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.bloodPressureAndPulse,
        },
      );
      final dataSelective = await harness.compileModularClinicalReportData(
        patientId: patient.id,
        config: configSelective,
        asOf: now,
      );
      expect(dataSelective.dialysisSessions, isEmpty);
      expect(dataSelective.bloodPressureLogs.length, equals(3));
      expect(dataSelective.accessInspections, isEmpty);
      expect(dataSelective.catheterEvents, isEmpty);

      final pdfSelectiveBytes = await harness.generateModularClinicalReportPdf(
        patientId: patient.id,
        config: configSelective,
        asOf: now,
        compress: false,
      );
      expect(pdfSelectiveBytes, isNotEmpty);
      expect(utf8.decode(pdfSelectiveBytes.sublist(0, 5)), equals('%PDF-'));

      final pdfContent = String.fromCharCodes(pdfSelectiveBytes);
      expect(pdfContent, contains('[(Demographics)]'));
      expect(pdfContent, contains('[(Hemodynamic)]'));
      expect(pdfContent, isNot(contains('Pre/Post/Prescribed')));
      expect(pdfContent, isNot(contains('[(Intake)]')));
      expect(pdfContent, isNot(contains('[(Lifespan)]')));
    });

    test('Vascular Access Catalog & Selective Fistula Arm Lockout end-to-end clinical workflow', () async {
      final now = DateTime.now().toUtc();

      // 1. Non-Tunneled Temporary Line at Neck (Internal Jugular)
      final neckPatient = await harness.createPatient(
        name: 'Vas-Cath Neck Patient',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 72.0,
        vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
        fistulaArmLocation: AccessLocation.neck.name,
      );

      // Verify patient domain properties
      expect(neckPatient.hasArmAccess, isFalse);
      expect(VascularAccessType.fromString(neckPatient.vascularAccessType), equals(VascularAccessType.nonTunneledTemporaryDialysisLine));
      expect(AccessLocation.fromString(neckPatient.fistulaArmLocation), equals(AccessLocation.neck));
      expect(VascularSafetyRules.hasArmAccess(neckPatient), isFalse);
      expect(VascularSafetyRules.isArmSafe(patient: neckPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: neckPatient, arm: 'rightArm'), isTrue);

      // Verify blood pressure can be recorded safely on both arms without lockout
      final bpNeckLeft = await harness.recordBloodPressure(
        patientId: neckPatient.id,
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        armUsed: 'leftArm',
        recordedAt: now.subtract(const Duration(hours: 3)),
      );
      expect(bpNeckLeft.armUsed, equals('leftArm'));
      expect(bpNeckLeft.isSafeArm, isTrue);

      final bpNeckRight = await harness.recordBloodPressure(
        patientId: neckPatient.id,
        systolic: 122,
        diastolic: 82,
        pulse: 74,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(hours: 2)),
      );
      expect(bpNeckRight.armUsed, equals('rightArm'));
      expect(bpNeckRight.isSafeArm, isTrue);

      // Verify access inspection logging for Non-Tunneled Line with exit-site infection checks
      final neckCheckIn = await harness.recordPreDialysisCheckIn(
        patientId: neckPatient.id,
        preWeightKg: 74.0,
        volumeAllowanceMl: 500,
        rednessPresent: true,
        swellingPresent: true,
        dischargePresent: false,
        painPresent: true,
        inspectionNotes: 'Neck insertion site dressing changed',
        startedAt: now.subtract(const Duration(hours: 1)),
      );
      expect(neckCheckIn.id, isNotEmpty);

      final neckInspections = await harness.getAccessInspections(neckPatient.id);
      expect(neckInspections.length, equals(1));
      expect(neckInspections.first.accessType, equals(VascularAccessType.nonTunneledTemporaryDialysisLine.name));
      expect(neckInspections.first.anatomicalLocation, equals(AccessLocation.neck.name));
      expect(neckInspections.first.rednessPresent, isTrue);
      expect(neckInspections.first.swellingPresent, isTrue);
      expect(neckInspections.first.dischargePresent, isFalse);
      expect(neckInspections.first.painPresent, isTrue);

      final neckWarnings = HemodialysisCalculationRules.getAccessSafetyWarnings(
        accessType: neckPatient.vascularAccessType!,
        rednessPresent: true,
        swellingPresent: true,
        dischargePresent: false,
        painPresent: true,
      );
      expect(neckWarnings.length, equals(3));
      expect(neckWarnings.any((w) => w.contains('redness')), isTrue);
      expect(neckWarnings.any((w) => w.contains('swelling')), isTrue);
      expect(neckWarnings.any((w) => w.contains('pain')), isTrue);
      // Ensure central lines do not raise thrill/bruit warnings
      expect(neckWarnings.any((w) => w.contains('thrill')), isFalse);
      expect(neckWarnings.any((w) => w.contains('bruit')), isFalse);

      // 2. Non-Tunneled Temporary Line at Thigh/Groin (Femoral)
      final femoralPatient = await harness.createPatient(
        name: 'Femoral Line Patient',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 68.0,
        vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
        fistulaArmLocation: AccessLocation.thighGroin.name,
      );

      expect(femoralPatient.hasArmAccess, isFalse);
      expect(AccessLocation.fromString(femoralPatient.fistulaArmLocation), equals(AccessLocation.thighGroin));
      expect(VascularSafetyRules.isArmSafe(patient: femoralPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: femoralPatient, arm: 'rightArm'), isTrue);

      final bpFemoralLeft = await harness.recordBloodPressure(
        patientId: femoralPatient.id,
        systolic: 125,
        diastolic: 84,
        pulse: 75,
        armUsed: 'leftArm',
        recordedAt: now,
      );
      expect(bpFemoralLeft.isSafeArm, isTrue);

      final femoralCheckIn = await harness.recordPreDialysisCheckIn(
        patientId: femoralPatient.id,
        preWeightKg: 70.0,
        rednessPresent: false,
        swellingPresent: false,
        dischargePresent: false,
        painPresent: false,
        startedAt: now,
      );
      expect(femoralCheckIn.id, isNotEmpty);

      final femoralInspections = await harness.getAccessInspections(femoralPatient.id);
      expect(femoralInspections.first.anatomicalLocation, equals(AccessLocation.thighGroin.name));
      final femoralWarnings = HemodialysisCalculationRules.getAccessSafetyWarnings(
        accessType: femoralPatient.vascularAccessType!,
        rednessPresent: false,
        swellingPresent: false,
        dischargePresent: false,
        painPresent: false,
      );
      expect(femoralWarnings, isEmpty);

      // 3. Tunneled Dialysis Central Line (Permcath) at Chest
      final chestPatient = await harness.createPatient(
        name: 'Permcath Chest Patient',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 65.0,
        vascularAccessType: VascularAccessType.tunneledDialysisCentralLine.name,
        fistulaArmLocation: AccessLocation.chest.name,
      );

      expect(chestPatient.hasArmAccess, isFalse);
      expect(VascularSafetyRules.isArmSafe(patient: chestPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: chestPatient, arm: 'rightArm'), isTrue);

      final chestWarnings = HemodialysisCalculationRules.getAccessSafetyWarnings(
        accessType: chestPatient.vascularAccessType!,
        rednessPresent: false,
        swellingPresent: false,
        dischargePresent: true,
        painPresent: false,
      );
      expect(chestWarnings.length, equals(1));
      expect(chestWarnings.first, contains('discharge'));

      // 4. Fistula on Left Arm: Strictly enforces hard lockout ONLY when access is located on an arm
      final fistulaPatient = await harness.createPatient(
        name: 'AV Fistula Left Arm Patient',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 60.0,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      expect(fistulaPatient.hasArmAccess, isTrue);
      expect(VascularSafetyRules.hasArmAccess(fistulaPatient), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: fistulaPatient, arm: 'leftArm'), isFalse);
      expect(VascularSafetyRules.isArmSafe(patient: fistulaPatient, arm: 'rightArm'), isTrue);
      expect(VascularSafetyRules.getProhibitedArm(fistulaPatient), equals('leftArm'));

      // Prohibited arm throws FistulaArmSafetyException
      expect(
        () => harness.recordBloodPressure(
          patientId: fistulaPatient.id,
          systolic: 130,
          diastolic: 85,
          pulse: 78,
          armUsed: 'leftArm',
          recordedAt: now,
        ),
        throwsA(isA<FistulaArmSafetyException>()),
      );

      // Safe arm (rightArm) succeeds
      final bpFistulaRight = await harness.recordBloodPressure(
        patientId: fistulaPatient.id,
        systolic: 128,
        diastolic: 82,
        pulse: 76,
        armUsed: 'rightArm',
        recordedAt: now,
      );
      expect(bpFistulaRight.armUsed, equals('rightArm'));
      expect(bpFistulaRight.isSafeArm, isTrue);
    });

    test('Top-level test harness verifies Multi-Condition Configurable Foley Catheter Lifespan, Scheduled Bag Reminders, and 1-Tap Bag Evacuation', () async {
      // 1. Accessibility across all clinical condition profiles
      // Hemodialysis patient
      final hdPatient = await harness.createPatient(
        name: 'HD Catheter Patient',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 72.0,
      );
      // Peritoneal Dialysis patient
      final pdPatient = await harness.createPatient(
        name: 'PD Catheter Patient',
        diagnosis: ClinicalCondition.peritonealDialysis.name,
        prescribedDryWeightKg: 68.0,
      );
      // Non-Dialysis CKD patient
      final ckdPatient = await harness.createPatient(
        name: 'CKD Catheter Patient',
        diagnosis: ClinicalCondition.nonDialysisCkd.name,
        prescribedDryWeightKg: 75.0,
      );
      // Urological / Catheter patient
      final uroPatient = await harness.createPatient(
        name: 'Urology Catheter Patient',
        diagnosis: ClinicalCondition.urologicalCatheter.name,
        prescribedDryWeightKg: 70.0,
      );

      final baseTime = DateTime.utc(2026, 9, 1, 8, 0);

      // 2. Material-driven lifespan & CAUTI Risk Window calculations
      // HD: 30-day silicone catheter with 6-hour bag emptying interval
      final hdCatheter = await harness.recordCatheterInsertion(
        patientId: hdPatient.id,
        insertionDate: baseTime,
        material: CatheterMaterial.silicone30Day,
        bagEmptyingIntervalHours: 6,
        notes: '30-day silicone catheter for HD patient',
      );
      expect(hdCatheter.material, equals('silicone30Day'));
      expect(hdCatheter.lifespanDays, equals(30));
      expect(hdCatheter.bagEmptyingIntervalHours, equals(6));
      expect(hdCatheter.replacementDueDate.isAtSameMomentAs(baseTime.add(const Duration(days: 30))), isTrue);

      // Verify 30-day lifespan summary calculations
      final hdDay1 = await harness.evaluateCatheterLifespan(hdPatient.id, asOf: baseTime);
      expect(hdDay1!.totalLifespanDays, equals(30));
      expect(hdDay1.material, equals(CatheterMaterial.silicone30Day));
      expect(hdDay1.status, equals(CatheterLifespanStatus.green));
      expect(hdDay1.daysRemaining, equals(30));
      expect(hdDay1.isCautiRiskActive, isFalse);

      final hdDay26 = await harness.evaluateCatheterLifespan(
        hdPatient.id,
        asOf: baseTime.add(const Duration(days: 25, hours: 1)),
      );
      expect(hdDay26!.status, equals(CatheterLifespanStatus.amber)); // <= 5 days remaining
      expect(hdDay26.daysRemaining, equals(5));
      expect(hdDay26.isCautiRiskActive, isFalse);

      final hdDay31 = await harness.evaluateCatheterLifespan(
        hdPatient.id,
        asOf: baseTime.add(const Duration(days: 30, hours: 2)),
      );
      expect(hdDay31!.status, equals(CatheterLifespanStatus.red));
      expect(hdDay31.isCautiRiskActive, isTrue);
      expect(hdDay31.daysOverdue, equals(1));

      // PD: 90-day silicone catheter with 8-hour interval
      final pdCatheter = await harness.recordCatheterInsertion(
        patientId: pdPatient.id,
        insertionDate: baseTime,
        material: CatheterMaterial.silicone90Day,
        bagEmptyingIntervalHours: 8,
      );
      expect(pdCatheter.material, equals('silicone90Day'));
      expect(pdCatheter.lifespanDays, equals(90));
      expect(pdCatheter.bagEmptyingIntervalHours, equals(8));
      expect(pdCatheter.replacementDueDate.isAtSameMomentAs(baseTime.add(const Duration(days: 90))), isTrue);

      // CKD: Custom 45-day duration catheter
      final ckdCatheter = await harness.recordCatheterInsertion(
        patientId: ckdPatient.id,
        insertionDate: baseTime,
        material: CatheterMaterial.custom,
        customLifespanDays: 45,
        bagEmptyingIntervalHours: 4,
      );
      expect(ckdCatheter.material, equals('custom'));
      expect(ckdCatheter.lifespanDays, equals(45));
      expect(ckdCatheter.replacementDueDate.isAtSameMomentAs(baseTime.add(const Duration(days: 45))), isTrue);

      final ckdSummary = await harness.evaluateCatheterLifespan(ckdPatient.id, asOf: baseTime);
      expect(ckdSummary!.totalLifespanDays, equals(45));

      // Urology: Standard 14-day latex catheter
      final uroCatheter = await harness.recordCatheterInsertion(
        patientId: uroPatient.id,
        insertionDate: baseTime,
        material: CatheterMaterial.latex14Day,
      );
      expect(uroCatheter.material, equals('latex14Day'));
      expect(uroCatheter.lifespanDays, equals(14));

      // 3. Scheduled Bag Emptying Reminders & 1-Tap "Bag Emptied" Action
      // At insertion + 4 hours (interval is 6h): not due yet
      final bagEvalBeforeDue = await harness.evaluateCatheterLifespan(
        hdPatient.id,
        asOf: baseTime.add(const Duration(hours: 4)),
      );
      expect(bagEvalBeforeDue!.isBagEmptyingDue, isFalse);
      expect(bagEvalBeforeDue.minutesUntilNextBagEmptying, equals(120));

      // At insertion + 7 hours: due!
      final bagEvalDue = await harness.evaluateCatheterLifespan(
        hdPatient.id,
        asOf: baseTime.add(const Duration(hours: 7)),
      );
      expect(bagEvalDue!.isBagEmptyingDue, isTrue);
      expect(bagEvalDue.minutesUntilNextBagEmptying, equals(0));

      // 1-tap "Bag Emptied" action: captures evacuation volume (400 mL) and Hematuria Grade 2 (Pink/Light Orange)
      final emptiedAt = baseTime.add(const Duration(hours: 7, minutes: 15));
      final bagResult = await harness.recordBagEmptied(
        patientId: hdPatient.id,
        volumeMl: 400,
        hematuriaGrade: 2,
        recordedAt: emptiedAt,
      );
      final bagLog = bagResult.outputLog;
      expect(bagLog.id, isNotEmpty);
      expect(bagLog.volumeMl, equals(400));
      expect(bagLog.hematuriaGrade, equals(2));
      expect(bagLog.outputType, equals('urine'));
      expect(bagResult.catheter.lastBagEmptiedAt, isNotNull);
      expect(bagResult.catheter.lastBagEmptiedAt!.isAtSameMomentAs(emptiedAt), isTrue);

      // Check that the bag emptying log persists in fluid output logs
      final outputs = await harness.getFluidOutputLogs(hdPatient.id);
      expect(outputs.length, equals(1));
      expect(outputs.first.id, equals(bagLog.id));
      expect(outputs.first.hematuriaGrade, equals(2));

      // Check that 24-hour Fluid Balance accounts for the bag evacuation volume
      final fluidBalance = await harness.get24HourFluidBalance(hdPatient.id, asOf: emptiedAt);
      expect(fluidBalance.totalOutputMl, equals(400));

      // Check that active catheter's lastBagEmptiedAt updated and nextBagEmptyingDue is reset
      final activeHdCatheter = await harness.getActiveCatheter(hdPatient.id);
      expect(activeHdCatheter!.lastBagEmptiedAt, isNotNull);
      expect(activeHdCatheter.lastBagEmptiedAt!.isAtSameMomentAs(emptiedAt), isTrue);

      final bagEvalAfter = await harness.evaluateCatheterLifespan(
        hdPatient.id,
        asOf: emptiedAt.add(const Duration(minutes: 30)),
      );
      expect(bagEvalAfter!.isBagEmptyingDue, isFalse);
      expect(bagEvalAfter.nextBagEmptyingDue!.isAtSameMomentAs(emptiedAt.add(const Duration(hours: 6))), isTrue);

      // 4. Catheter Replacement workflow across configurable materials
      final replacementDate = baseTime.add(const Duration(days: 30));
      final replacedCatheter = await harness.recordCatheterReplacement(
        patientId: hdPatient.id,
        replacementDate: replacementDate,
        material: CatheterMaterial.silicone90Day,
        bagEmptyingIntervalHours: 8,
        notes: 'Upgraded to 90-day silicone catheter',
      );
      expect(replacedCatheter.id, isNot(equals(hdCatheter.id)));
      expect(replacedCatheter.material, equals('silicone90Day'));
      expect(replacedCatheter.lifespanDays, equals(90));
      expect(replacedCatheter.bagEmptyingIntervalHours, equals(8));
      expect(replacedCatheter.replacementDueDate.isAtSameMomentAs(replacementDate.add(const Duration(days: 90))), isTrue);

      final hdHistory = await harness.getCatheterHistory(hdPatient.id);
      expect(hdHistory.length, equals(2));
      expect(hdHistory.firstWhere((c) => c.id == hdCatheter.id).status, equals('replaced'));
      expect(hdHistory.firstWhere((c) => c.id == replacedCatheter.id).status, equals('active'));

      final replacementSummary = await harness.evaluateCatheterLifespan(hdPatient.id, asOf: replacementDate);
      expect(replacementSummary!.totalLifespanDays, equals(90));
      expect(replacementSummary.material, equals(CatheterMaterial.silicone90Day));
      expect(replacementSummary.status, equals(CatheterLifespanStatus.green));
      expect(replacementSummary.daysRemaining, equals(90));
      expect(replacementSummary.isCautiRiskActive, isFalse);
    });

    test('Top-level test harness verifies Medication Regimen management, 1-tap administration, and meal-binder synchronization', () async {
      final now = DateTime.now().toUtc();
      final patient = await harness.createPatient(
        name: 'Robert Oppenheimer',
        diagnosis: 'hemodialysis',
        dailyFluidAllowanceMl: 1000,
        prescribedDryWeightKg: 68.0,
      );

      // 1. Prescribe active regimens with clinical classifications
      final binderMed = await harness.createMedication(
        patientId: patient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800 mg',
        frequency: 'Three times daily with meals',
        instructions: 'Take during or immediately after meals to sequester dietary phosphorus',
        isPhosphateBinder: true,
        isAntiHypertensive: false,
        isActive: true,
      );

      final antiHypertensiveMed = await harness.createMedication(
        patientId: patient.id,
        name: 'Amlodipine Besylate',
        dosage: '5 mg',
        frequency: 'Once daily morning',
        instructions: 'Monitor blood pressure before and 30 minutes after taking',
        isPhosphateBinder: false,
        isAntiHypertensive: true,
        isActive: true,
      );

      final discontinuedMed = await harness.createMedication(
        patientId: patient.id,
        name: 'Old Diuretic',
        dosage: '20 mg',
        frequency: 'Once daily',
        isActive: false,
      );

      // Verify active medications query filters out inactive
      final activeMeds = await harness.getActiveMedications(patient.id);
      expect(activeMeds.length, equals(2));
      expect(activeMeds.any((m) => m.id == binderMed.id), isTrue);
      expect(activeMeds.any((m) => m.id == antiHypertensiveMed.id), isTrue);
      expect(activeMeds.any((m) => m.id == discontinuedMed.id), isFalse);

      final allMeds = await harness.getAllMedications(patient.id);
      expect(allMeds.length, equals(3));

      // 2. Verify active Phosphate Binder detection for meal/fluid intake prompts
      expect(await harness.hasActivePhosphateBinders(patient.id), isTrue);
      final activeBinders = await harness.getActivePhosphateBinders(patient.id);
      expect(activeBinders.length, equals(1));
      expect(activeBinders.first.name, equals('Sevelamer Carbonate'));

      // 3. 1-Tap Administration Logging from dashboard or medication screen
      final adminTime = now.subtract(const Duration(hours: 1));
      final adminRecord = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: binderMed.id,
        administeredAt: adminTime,
      );

      expect(adminRecord.id, isNotEmpty);
      expect(adminRecord.patientId, equals(patient.id));
      expect(adminRecord.medicationId, equals(binderMed.id));
      expect(adminRecord.medicationName, equals('Sevelamer Carbonate'));
      expect(adminRecord.dosage, equals('800 mg'));
      expect(adminRecord.isPhosphateBinder, isTrue);
      expect(adminRecord.isAntiHypertensive, isFalse);

      // Verify 1-tap administration of anti-hypertensive
      final ahAdmin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: antiHypertensiveMed.id,
      );
      expect(ahAdmin.isAntiHypertensive, isTrue);
      expect(ahAdmin.medicationName, equals('Amlodipine Besylate'));

      // Verify query returns both administrations
      final admins = await harness.getMedicationAdministrations(patient.id);
      expect(admins.length, equals(2));

      // 4. Meal and Fluid Intake synchronization: fluid intake with phosphate binder taken
      final intake = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 250,
        beverageType: 'Water with Lunch',
        phosphateBinderTaken: true,
        recordedAt: now,
      );
      expect(intake.phosphateBinderTaken, isTrue);

      // 5. Editing and deleting administration records to ensure adherence data integrity
      final updatedAdmin = await harness.updateMedicationAdministration(
        id: adminRecord.id,
        dosage: '1600 mg',
        notes: 'Double dose with heavy protein meal per nephrologist advice',
      );
      expect(updatedAdmin.dosage, equals('1600 mg'));
      expect(updatedAdmin.notes, equals('Double dose with heavy protein meal per nephrologist advice'));

      // Delete accidental administration
      final accidentalAdmin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: binderMed.id,
        notes: 'Accidental double tap entry',
      );
      final preDeleteList = await harness.getMedicationAdministrations(patient.id);
      expect(preDeleteList.length, equals(3));

      final deletedCount = await harness.deleteMedicationAdministration(accidentalAdmin.id);
      expect(deletedCount, equals(1));

      final postDeleteList = await harness.getMedicationAdministrations(patient.id);
      expect(postDeleteList.length, equals(2));
      expect(postDeleteList.any((a) => a.id == accidentalAdmin.id), isFalse);
    });

    test('End-to-End Clinical Workflow: Unified Hemodialysis Session Lifecycle & Intradialytic Monitoring (#15)', () async {
      // 1. Setup Patient Profile with Prescribed Dry Weight & Vascular Access
      final patient = await harness.createPatient(
        name: 'Unified Dialysis Patient',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 70.0,
        dailyFluidAllowanceMl: 1500,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      // 2. Pre-Dialysis Check-in: captures pre-weight, computes IDWG & UF Goal with rinseback allowance, inspects fistula
      final checkInTime = DateTime.now().subtract(const Duration(hours: 4)).toUtc();
      final session = await harness.recordPreDialysisCheckIn(
        patientId: patient.id,
        preWeightKg: 73.2,
        volumeAllowanceMl: 300, // 300 mL rinseback / intra-treatment allowance
        notes: 'Pre-session vitals stable',
        startedAt: checkInTime,
        thrillPresent: true,
        bruitPresent: true,
        rednessPresent: false,
        swellingPresent: false,
        dischargePresent: false,
        painPresent: false,
      );

      expect(session.id, isNotEmpty);
      expect(session.patientId, equals(patient.id));
      expect(session.status, equals('inProgress'));
      expect(session.preWeightKg, equals(73.2));
      // First session IDWG: 73.2 - 70.0 = 3.2 kg
      expect(session.calculatedInterdialyticWeightGainKg, equals(3.2));
      // UF Goal: (3.2 * 1000) + 300 mL allowance = 3500 mL
      expect(session.calculatedUltrafiltrationGoalMl, equals(3500));

      // 3. Active Session Surveillance: query active session
      final activeSession = await harness.getActiveDialysisSession(patient.id);
      expect(activeSession, isNotNull);
      expect(activeSession!.id, equals(session.id));
      expect(activeSession.status, equals('inProgress'));

      // 4. Post-Dialysis Checkout: completes continuous session entity with post-weight, variance, symptoms, and actual UF
      final checkOutTime = DateTime.now().toUtc();
      final completedSession = await harness.recordPostDialysisSession(
        sessionId: session.id, // Operate on the single continuous entity
        postWeightKg: 70.3,
        actualFluidRemovedMl: 3450,
        symptoms: ['muscle cramping', 'dizziness', 'headache', 'nausea', 'post-dialysis fatigue'],
        notes: 'Mild leg cramps relieved by reducing UF rate at 3.5h',
        endedAt: checkOutTime,
      );

      // Verify single continuous entity integrity
      expect(completedSession.id, equals(session.id));
      expect(completedSession.status, equals('completed'));
      expect(completedSession.preWeightKg, equals(73.2));
      expect(completedSession.postWeightKg, equals(70.3));
      // Difference against Prescribed Dry Weight: 70.3 - 70.0 = +0.3 kg
      expect(completedSession.calculatedPostWeightDifferenceKg, equals(0.3));
      expect(completedSession.actualFluidRemovedMl, equals(3450));
      expect(completedSession.symptoms, contains('muscle cramping'));
      expect(completedSession.symptoms, contains('dizziness'));
      expect(completedSession.symptoms, contains('headache'));
      expect(completedSession.symptoms, contains('nausea'));
      expect(completedSession.symptoms, contains('post-dialysis fatigue'));
      expect(completedSession.endedAt, isNotNull);

      // 5. Active session is cleared after checkout completion
      final activeAfterCheckout = await harness.getActiveDialysisSession(patient.id);
      expect(activeAfterCheckout, isNull);

      // 6. Sequential Session: Interdialytic Weight Gain calculated against previous completed session post-weight
      final nextSessionTime = DateTime.now().add(const Duration(days: 2)).toUtc();
      final nextSession = await harness.recordPreDialysisCheckIn(
        patientId: patient.id,
        preWeightKg: 72.5,
        volumeAllowanceMl: 200,
        startedAt: nextSessionTime,
      );

      // IDWG: 72.5 - 70.3 (previous completed session post-weight) = 2.2 kg
      expect(nextSession.calculatedInterdialyticWeightGainKg, equals(2.2));
      // UF Goal: (72.5 - 70.0) * 1000 + 200 = 2700 mL
      expect(nextSession.calculatedUltrafiltrationGoalMl, equals(2700));
      expect(nextSession.status, equals('inProgress'));

      // 7. Session Cancellation lifecycle
      final cancelledSession = await harness.cancelDialysisSession(
        nextSession.id,
        reason: 'Severe hypotension during priming',
      );
      expect(cancelledSession.id, equals(nextSession.id));
      expect(cancelledSession.status, equals('cancelled'));
      expect(cancelledSession.endedAt, isNotNull);
      expect(cancelledSession.notes, contains('Severe hypotension during priming'));

      // Active session should be clear again
      final activeAfterCancel = await harness.getActiveDialysisSession(patient.id);
      expect(activeAfterCancel, isNull);
    });

    test('End-to-End Clinical Workflow: Paired Anti-Hypertensive Blood Pressure Assessment Protocol & Background Alarm (#16)', () async {
      // 1. Setup Patient Profile with Vascular Access and Fistula Arm Safety Flag
      final patient = await harness.createPatient(
        name: 'Hypertensive Hemodialysis Patient',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 68.0,
        dailyFluidAllowanceMl: 1500,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      // 2. Prescribe Anti-Hypertensive Regimen (Amlodipine)
      final antiHypMed = await harness.createMedication(
        patientId: patient.id,
        name: 'Amlodipine',
        dosage: '10 mg',
        frequency: 'Daily in morning',
        isAntiHypertensive: true,
      );
      expect(antiHypMed.id, isNotEmpty);
      expect(antiHypMed.isAntiHypertensive, isTrue);

      // 3. 1-Tap Administration of Anti-Hypertensive
      final adminTime = DateTime.utc(2026, 9, 9, 8, 0, 0);
      final admin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: antiHypMed.id,
        administeredAt: adminTime,
      );
      expect(admin.id, isNotEmpty);
      expect(admin.isAntiHypertensive, isTrue);

      // 4. Baseline BP Measurement Lockout Verification: Fistula Arm Safety Flag prohibits leftArm
      expect(
        () => harness.recordBaselineBloodPressure(
          patientId: patient.id,
          medicationAdministrationId: admin.id,
          medicationName: antiHypMed.name,
          systolic: 168,
          diastolic: 104,
          pulse: 88,
          armUsed: 'leftArm', // Prohibited fistula arm!
          recordedAt: adminTime,
        ),
        throwsA(isA<FistulaArmSafetyException>()),
      );

      // 5. Record Baseline BP Measurement on verified safe arm (rightArm)
      final baseline = await harness.recordBaselineBloodPressure(
        patientId: patient.id,
        medicationAdministrationId: admin.id,
        medicationName: antiHypMed.name,
        systolic: 168,
        diastolic: 104,
        pulse: 88,
        armUsed: 'rightArm',
        onsetWindowMinutes: 30,
        recordedAt: adminTime,
      );

      expect(baseline.id, isNotEmpty);
      expect(baseline.isPairedAssessment, isTrue);
      expect(baseline.pairedRole, equals('baseline'));
      expect(baseline.pairedAssessmentId, isNotNull);
      expect(baseline.medicationAdministrationId, equals(admin.id));
      expect(baseline.systolic, equals(168));
      expect(baseline.diastolic, equals(104));
      expect(baseline.pulse, equals(88));
      expect(baseline.armUsed, equals('rightArm'));
      expect(baseline.isSafeArm, isTrue);
      expect(baseline.elapsedMinutes, isNull);
      expect(baseline.systolicDelta, isNull);
      expect(baseline.diastolicDelta, isNull);
      expect(baseline.pulseDelta, isNull);

      // 6. Background Alarm Scheduled Verification (30 min post-dose)
      final alarmService = harness.pairedBpAlarmService;
      final alarm = alarmService.getAlarmForAssessment(baseline.pairedAssessmentId!);
      expect(alarm, isNotNull);
      expect(alarm!.intervalMinutes, equals(30));
      expect(alarm.scheduledFor, equals(adminTime.add(const Duration(minutes: 30))));
      expect(alarm.medicationName, equals('Amlodipine'));
      expect(alarm.safeArm, equals('rightArm'));
      expect(alarm.baselineSystolic, equals(168));
      expect(alarm.baselineDiastolic, equals(104));
      expect(alarm.baselinePulse, equals(88));

      // 7. Surveillance: verify pending follow-up is active
      final pendingAssessments = await harness.getPendingFollowUpAssessments(patient.id);
      expect(pendingAssessments.length, equals(1));
      expect(pendingAssessments.first.id, equals(baseline.id));

      // 8. Follow-up BP measurement after 30 minutes
      final followUpTime = adminTime.add(const Duration(minutes: 30));
      final followUp = await harness.recordFollowUpBloodPressure(
        patientId: patient.id,
        pairedAssessmentId: baseline.pairedAssessmentId!,
        systolic: 136,
        diastolic: 84,
        pulse: 76,
        armUsed: 'rightArm',
        recordedAt: followUpTime,
      );

      expect(followUp.id, isNotEmpty);
      expect(followUp.isPairedAssessment, isTrue);
      expect(followUp.pairedRole, equals('followUp'));
      expect(followUp.pairedAssessmentId, equals(baseline.pairedAssessmentId));
      expect(followUp.medicationAdministrationId, equals(admin.id));
      expect(followUp.systolic, equals(136));
      expect(followUp.diastolic, equals(84));
      expect(followUp.pulse, equals(76));

      // 9. Exact elapsed minutes & hemodynamic deltas relative to baseline
      expect(followUp.elapsedMinutes, equals(30));
      expect(followUp.systolicDelta, equals(-32)); // 136 - 168 = -32 mmHg
      expect(followUp.diastolicDelta, equals(-20)); // 84 - 104 = -20 mmHg
      expect(followUp.pulseDelta, equals(-12)); // 76 - 88 = -12 bpm

      // 10. Alarm cleared & pending follow-up resolved
      expect(alarmService.getAlarmForAssessment(baseline.pairedAssessmentId!), isNull);
      final pendingAfter = await harness.getPendingFollowUpAssessments(patient.id);
      expect(pendingAfter, isEmpty);

      // 11. Paired assessment remains queryable and linked to drug administration record
      final pairedList = await harness.getPairedAssessments(patient.id);
      expect(pairedList.length, equals(1));
      final pair = pairedList.first;
      expect(pair.baseline.id, equals(baseline.id));
      expect(pair.followUp?.id, equals(followUp.id));
      expect(pair.isCompleted, isTrue);
      expect(pair.elapsedMinutes, equals(30));
      expect(pair.systolicDelta, equals(-32));
      expect(pair.diastolicDelta, equals(-20));
      expect(pair.pulseDelta, equals(-12));
      expect(pair.medicationAdministrationId, equals(admin.id));

      final byAdmin = await harness.getPairedAssessmentForAdministration(admin.id);
      expect(byAdmin, isNotNull);
      expect(byAdmin!.pairedAssessmentId, equals(baseline.pairedAssessmentId));
      expect(byAdmin.baseline.id, equals(baseline.id));
      expect(byAdmin.followUp?.id, equals(followUp.id));
    });
  });
}

