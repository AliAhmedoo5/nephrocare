import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dialysis/data/dialysis_session_repository.dart';
import 'package:nephrocare/src/features/dialysis/domain/hemodialysis_calculation_rules.dart';
import 'package:nephrocare/src/features/fluid/data/fluid_repository.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';

void main() {
  group('Domain/Repository Seam: Hemodialysis Calculations & Drift Persistence', () {
    late NephroTestHarness harness;
    late DialysisSessionRepository repository;

    setUp(() {
      harness = createNephroTestHarness();
      repository = DialysisSessionRepository(harness.database);
    });

    tearDown(() async {
      await harness.dispose();
    });

    group('HemodialysisCalculationRules', () {
      test('calculates Interdialytic Weight Gain against previous session post-weight', () {
        final idwg = HemodialysisCalculationRules.calculateInterdialyticWeightGain(
          currentPreWeightKg: 72.4,
          previousPostWeightKg: 70.0,
          prescribedDryWeightKg: 69.5,
        );

        // 72.4 - 70.0 = 2.4 kg
        expect(idwg, equals(2.4));
      });

      test('falls back to prescribed dry weight when no previous post-weight exists', () {
        final idwg = HemodialysisCalculationRules.calculateInterdialyticWeightGain(
          currentPreWeightKg: 72.4,
          previousPostWeightKg: null,
          prescribedDryWeightKg: 70.0,
        );

        // 72.4 - 70.0 = 2.4 kg
        expect(idwg, equals(2.4));
      });

      test('calculates Ultrafiltration Goal with volume allowances', () {
        // Pre-weight: 72.5 kg, Prescribed Dry Weight: 70.0 kg
        // Fluid excess to remove = 2.5 kg = 2500 mL
        // Volume allowance = 300 mL (e.g. rinseback/infusion)
        // Total UF Goal = 2500 + 300 = 2800 mL
        final ufGoal = HemodialysisCalculationRules.calculateUltrafiltrationGoal(
          currentPreWeightKg: 72.5,
          prescribedDryWeightKg: 70.0,
          volumeAllowanceMl: 300,
        );

        expect(ufGoal, equals(2800));
      });

      test('clamps Ultrafiltration Goal to zero if patient is below prescribed dry weight', () {
        final ufGoal = HemodialysisCalculationRules.calculateUltrafiltrationGoal(
          currentPreWeightKg: 68.0,
          prescribedDryWeightKg: 70.0,
          volumeAllowanceMl: 0,
        );

        expect(ufGoal, equals(0));
      });

      test('calculates post-weight difference from Prescribed Dry Weight', () {
        // Patient finished at 70.2 kg, dry weight 70.0 kg -> +0.2 kg fluid excess
        final diff1 = HemodialysisCalculationRules.calculatePostWeightDifference(
          postWeightKg: 70.2,
          prescribedDryWeightKg: 70.0,
        );
        expect(diff1, equals(0.2));

        // Patient finished at 69.7 kg, dry weight 70.0 kg -> -0.3 kg below dry weight
        final diff2 = HemodialysisCalculationRules.calculatePostWeightDifference(
          postWeightKg: 69.7,
          prescribedDryWeightKg: 70.0,
        );
        expect(diff2, equals(-0.3));
      });

      test('validates access inspection safety for AV Fistula/Graft (thrill and bruit)', () {
        // Fistula with thrill and bruit present -> safe
        final fistulaSafe = HemodialysisCalculationRules.getAccessSafetyWarnings(
          accessType: VascularAccessType.arteriovenousFistula.name,
          thrillPresent: true,
          bruitPresent: true,
        );
        expect(fistulaSafe, isEmpty);

        // Fistula missing thrill or bruit -> warning flagged
        final fistulaWarning = HemodialysisCalculationRules.getAccessSafetyWarnings(
          accessType: VascularAccessType.arteriovenousFistula.name,
          thrillPresent: false,
          bruitPresent: true,
        );
        expect(fistulaWarning, contains('Absent thrill detected in vascular fistula/graft.'));
      });

      test('validates access inspection safety for Dialysis Central Line (redness, swelling, discharge)', () {
        // Central line with redness and discharge -> warnings flagged
        final lineWarnings = HemodialysisCalculationRules.getAccessSafetyWarnings(
          accessType: VascularAccessType.dialysisCentralLine.name,
          rednessPresent: true,
          swellingPresent: true,
          dischargePresent: true,
          painPresent: true,
        );

        expect(lineWarnings.length, equals(4));
        expect(lineWarnings, contains('Exit-site redness detected.'));
        expect(lineWarnings, contains('Exit-site swelling detected.'));
        expect(lineWarnings, contains('Exit-site discharge detected.'));
        expect(lineWarnings, contains('Exit-site pain reported.'));
      });
    });

    group('DialysisSessionRepository', () {
      test('records pre-dialysis check-in, computes IDWG and UF goal, and persists in Drift SQLite with UUIDv4', () async {
        final patient = await harness.createPatient(
          name: 'Arthur Dent',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 70.0,
          vascularAccessType: VascularAccessType.arteriovenousFistula.name,
          fistulaArmLocation: AccessLocation.leftArm.name,
        );

        final session = await repository.recordPreDialysisCheckIn(
          patientId: patient.id,
          preWeightKg: 72.8,
          volumeAllowanceMl: 300,
          notes: 'Routine Tuesday session',
          thrillPresent: true,
          bruitPresent: true,
        );

        expect(session.id, isNotEmpty);
        expect(
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
              .hasMatch(session.id),
          isTrue,
        );
        expect(session.patientId, equals(patient.id));
        expect(session.preWeightKg, equals(72.8));
        // First session: IDWG calculated against dry weight: 72.8 - 70.0 = 2.8 kg
        expect(session.calculatedInterdialyticWeightGainKg, equals(2.8));
        // UF Goal: (2.8 * 1000) + 300 = 3100 mL
        expect(session.calculatedUltrafiltrationGoalMl, equals(3100));
        expect(session.createdAt, isNotNull);
        expect(session.updatedAt, isNotNull);

        // Verify AccessInspection was also recorded
        final inspections = await repository.getAccessInspections(patient.id);
        expect(inspections.length, equals(1));
        expect(inspections.first.accessType, equals(VascularAccessType.arteriovenousFistula.name));
        expect(inspections.first.thrillPresent, isTrue);
        expect(inspections.first.bruitPresent, isTrue);
      });

      test('computes IDWG across sequential sessions and logs post-session data with symptoms', () async {
        final patient = await harness.createPatient(
          name: 'Ford Prefect',
          diagnosis: ClinicalCondition.hemodialysis.name,
          prescribedDryWeightKg: 68.0,
          vascularAccessType: VascularAccessType.dialysisCentralLine.name,
          fistulaArmLocation: AccessLocation.chest.name,
        );

        // Session 1: Pre-weight 70.5 kg, Post-weight 68.2 kg
        final session1 = await repository.recordPreDialysisCheckIn(
          patientId: patient.id,
          preWeightKg: 70.5,
          volumeAllowanceMl: 200,
          startedAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        final completedSession1 = await repository.recordPostDialysisSession(
          sessionId: session1.id,
          postWeightKg: 68.2,
          actualFluidRemovedMl: 2500,
          symptoms: ['cramping'],
          notes: 'Mild calf cramps during final 30 mins',
          endedAt: DateTime.now().subtract(const Duration(days: 2, hours: -4)),
        );

        expect(completedSession1.postWeightKg, equals(68.2));
        // Difference from dry weight: 68.2 - 68.0 = +0.2 kg
        expect(completedSession1.calculatedPostWeightDifferenceKg, equals(0.2));
        expect(completedSession1.symptoms, contains('cramping'));
        expect(completedSession1.actualFluidRemovedMl, equals(2500));

        // Session 2: Pre-weight 71.0 kg
        // IDWG against previous session post-weight: 71.0 - 68.2 = 2.8 kg!
        final session2 = await repository.recordPreDialysisCheckIn(
          patientId: patient.id,
          preWeightKg: 71.0,
          volumeAllowanceMl: 250,
          startedAt: DateTime.now(),
        );

        expect(session2.calculatedInterdialyticWeightGainKg, equals(2.8));
        // UF Goal: (71.0 - 68.0) * 1000 + 250 = 3250 mL
        expect(session2.calculatedUltrafiltrationGoalMl, equals(3250));

        // Complete Session 2 with dizziness and hypotension
        final completedSession2 = await repository.recordPostDialysisSession(
          sessionId: session2.id,
          postWeightKg: 67.8,
          actualFluidRemovedMl: 3200,
          symptoms: ['dizziness', 'hypotension'],
          endedAt: DateTime.now().add(const Duration(hours: 4)),
        );

        expect(completedSession2.postWeightKg, equals(67.8));
        // 67.8 - 68.0 = -0.2 kg
        expect(completedSession2.calculatedPostWeightDifferenceKg, equals(-0.2));
        expect(completedSession2.symptoms, contains('dizziness'));
        expect(completedSession2.symptoms, contains('hypotension'));
      });

      test('recordAccessInspection persists standalone inspection and streams longitudinal timeline', () async {
        final patient = await harness.createPatient(
          name: 'Access Test Patient',
          diagnosis: 'peritonealDialysis',
          vascularAccessType: 'peritonealDialysisAccess',
          fistulaArmLocation: 'abdomen',
        );

        final now = DateTime.now().toUtc();
        final inspection1 = await repository.recordAccessInspection(
          patientId: patient.id,
          accessType: 'peritonealDialysisAccess',
          anatomicalLocation: 'abdomen',
          rednessPresent: false,
          swellingPresent: false,
          dischargePresent: false,
          painPresent: false,
          notes: 'Baseline healthy exit site',
          recordedAt: now.subtract(const Duration(days: 2)),
        );

        expect(inspection1.id, isNotEmpty);
        expect(inspection1.accessType, equals('peritonealDialysisAccess'));
        expect(inspection1.rednessPresent, isFalse);

        final inspection2 = await repository.recordAccessInspection(
          patientId: patient.id,
          accessType: 'peritonealDialysisAccess',
          anatomicalLocation: 'abdomen',
          rednessPresent: true,
          swellingPresent: true,
          dischargePresent: false,
          painPresent: true,
          notes: 'Erythema and swelling observed',
          recordedAt: now,
        );

        expect(inspection2.id, isNotEmpty);
        expect(inspection2.rednessPresent, isTrue);

        // Verify longitudinal timeline ordering (most recent first)
        final timeline = await repository.getAccessInspections(patient.id);
        expect(timeline.length, equals(2));
        expect(timeline.first.id, equals(inspection2.id));
        expect(timeline.last.id, equals(inspection1.id));
      });

      test('recordPeritonealExchange computes peritoneal ultrafiltration and integrates into 24h fluid balance', () async {
        final patient = await harness.createPatient(
          name: 'PD Test Patient',
          diagnosis: 'peritonealDialysis',
          prescribedDryWeightKg: 70.0,
          dailyFluidAllowanceMl: 1500,
        );

        final now = DateTime.now().toUtc();
        // Record PD exchange: 2000 mL inflow, 2350 mL drain -> Net UF +350 mL
        final exchange = await repository.recordPeritonealExchange(
          patientId: patient.id,
          inflowVolumeMl: 2000,
          drainVolumeMl: 2350,
          clarity: 'Clear',
          notes: 'Standard morning exchange',
          recordedAt: now,
        );

        expect(exchange.id, isNotEmpty);
        expect(exchange.sessionType, equals('peritoneal'));
        expect(exchange.actualFluidRemovedMl, equals(350));
        expect(exchange.notes, contains('Inflow: 2000 mL'));
        expect(exchange.notes, contains('Drain: 2350 mL'));
        expect(exchange.notes, contains('Net UF: +350 mL'));
        expect(exchange.notes, contains('Clarity: Clear'));

        // Verify that 24h Fluid Balance reflects peritoneal ultrafiltration extraction
        final fluidRepo = FluidRepository(harness.database);
        // Add 1000 mL intake
        await fluidRepo.recordFluidIntake(
          patientId: patient.id,
          volumeMl: 1000,
          beverageType: 'Water',
          recordedAt: now,
        );

        final balance = await fluidRepo.get24HourFluidBalance(patient.id, asOf: now);
        expect(balance.totalIntakeMl, equals(1000));
        expect(balance.totalOutputMl, equals(350));
        // Net balance: 1000 - 350 = +650 mL
        expect(balance.netBalanceMl, equals(650));
      });

      test('recordSymptomLog stores symptoms and notes for CKD / catheter surveillance', () async {
        final patient = await harness.createPatient(
          name: 'CKD Symptom Patient',
          diagnosis: 'nonDialysisCkd',
        );

        final now = DateTime.now().toUtc();
        final symptomLog = await repository.recordSymptomLog(
          patientId: patient.id,
          symptoms: ['fatigue', 'edema', 'loss_of_appetite'],
          notes: 'Noticeable ankle swelling in the evening',
          recordedAt: now,
          sessionType: 'ckd_symptom',
        );

        expect(symptomLog.id, isNotEmpty);
        expect(symptomLog.sessionType, equals('ckd_symptom'));
        expect(symptomLog.symptoms, equals('fatigue, edema, loss_of_appetite'));
        expect(symptomLog.notes, equals('Noticeable ankle swelling in the evening'));

        final sessions = await repository.getSessions(patient.id);
        expect(sessions.length, equals(1));
        expect(sessions.first.symptoms, contains('edema'));
      });
    });
  });
}
