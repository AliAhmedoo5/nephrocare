import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/blood_pressure/data/blood_pressure_repository.dart';
import 'package:nephrocare/src/features/blood_pressure/domain/vascular_safety_rules.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';

void main() {
  group('Domain/Repository Seam: Vascular Access Safety Rules & Blood Pressure Persistence', () {
    late NephroTestHarness harness;
    late BloodPressureRepository repository;

    setUp(() {
      harness = createNephroTestHarness();
      repository = BloodPressureRepository(harness.database);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Identifies safe arm and prohibited arm correctly per ADR-0003 and ADR-0005', () async {
      final leftFistulaPatient = await harness.createPatient(
        name: 'Jane Doe',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      expect(VascularSafetyRules.hasArmAccess(leftFistulaPatient), isTrue);
      expect(VascularSafetyRules.getProhibitedArm(leftFistulaPatient), equals('leftArm'));
      expect(VascularSafetyRules.getSafeArm(leftFistulaPatient), equals('rightArm'));
      expect(VascularSafetyRules.isArmSafe(patient: leftFistulaPatient, arm: 'leftArm'), isFalse);
      expect(VascularSafetyRules.isArmSafe(patient: leftFistulaPatient, arm: 'rightArm'), isTrue);

      final rightGraftPatient = await harness.createPatient(
        name: 'Robert Paulson',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.arteriovenousGraft.name,
        fistulaArmLocation: AccessLocation.rightArm.name,
      );

      expect(VascularSafetyRules.hasArmAccess(rightGraftPatient), isTrue);
      expect(VascularSafetyRules.getProhibitedArm(rightGraftPatient), equals('rightArm'));
      expect(VascularSafetyRules.getSafeArm(rightGraftPatient), equals('leftArm'));
      expect(VascularSafetyRules.isArmSafe(patient: rightGraftPatient, arm: 'rightArm'), isFalse);
      expect(VascularSafetyRules.isArmSafe(patient: rightGraftPatient, arm: 'leftArm'), isTrue);

      // Non-Tunneled Temporary Dialysis Line in the Neck (Internal Jugular)
      final neckVasCathPatient = await harness.createPatient(
        name: 'Alice Neck',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
        fistulaArmLocation: AccessLocation.neck.name,
      );

      expect(VascularSafetyRules.hasArmAccess(neckVasCathPatient), isFalse);
      expect(VascularSafetyRules.getProhibitedArm(neckVasCathPatient), isNull);
      expect(VascularSafetyRules.getSafeArm(neckVasCathPatient), isNull);
      expect(VascularSafetyRules.isArmSafe(patient: neckVasCathPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: neckVasCathPatient, arm: 'rightArm'), isTrue);

      // Non-Tunneled Temporary Dialysis Line in the Thigh / Groin (Femoral)
      final femoralVasCathPatient = await harness.createPatient(
        name: 'Bob Femoral',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
        fistulaArmLocation: AccessLocation.thighGroin.name,
      );

      expect(VascularSafetyRules.hasArmAccess(femoralVasCathPatient), isFalse);
      expect(VascularSafetyRules.getProhibitedArm(femoralVasCathPatient), isNull);
      expect(VascularSafetyRules.getSafeArm(femoralVasCathPatient), isNull);
      expect(VascularSafetyRules.isArmSafe(patient: femoralVasCathPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: femoralVasCathPatient, arm: 'rightArm'), isTrue);

      // Tunneled Central Line in the Chest (Permcath)
      final chestPermcathPatient = await harness.createPatient(
        name: 'John Smith',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.tunneledDialysisCentralLine.name,
        fistulaArmLocation: AccessLocation.chest.name,
      );

      expect(VascularSafetyRules.hasArmAccess(chestPermcathPatient), isFalse);
      expect(VascularSafetyRules.getProhibitedArm(chestPermcathPatient), isNull);
      expect(VascularSafetyRules.getSafeArm(chestPermcathPatient), isNull);
      expect(VascularSafetyRules.isArmSafe(patient: chestPermcathPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: chestPermcathPatient, arm: 'rightArm'), isTrue);

      // Peritoneal Dialysis in Abdomen
      final pdPatient = await harness.createPatient(
        name: 'Carla Belly',
        diagnosis: ClinicalCondition.peritonealDialysis.name,
        vascularAccessType: VascularAccessType.peritonealDialysisAccess.name,
        fistulaArmLocation: AccessLocation.abdomen.name,
      );

      expect(VascularSafetyRules.hasArmAccess(pdPatient), isFalse);
      expect(VascularSafetyRules.getProhibitedArm(pdPatient), isNull);
      expect(VascularSafetyRules.isArmSafe(patient: pdPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: pdPatient, arm: 'rightArm'), isTrue);

      // None / Not Applicable
      final nonePatient = await harness.createPatient(
        name: 'David None',
        diagnosis: ClinicalCondition.nonDialysisCkd.name,
        vascularAccessType: VascularAccessType.none.name,
        fistulaArmLocation: AccessLocation.none.name,
      );

      expect(VascularSafetyRules.hasArmAccess(nonePatient), isFalse);
      expect(VascularSafetyRules.getProhibitedArm(nonePatient), isNull);
      expect(VascularSafetyRules.isArmSafe(patient: nonePatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: nonePatient, arm: 'rightArm'), isTrue);
    });

    test('Allows blood pressure recording on both arms for patients with neck, chest, thigh/groin, and abdominal accesses', () async {
      final neckPatient = await harness.createPatient(
        name: 'Alice Neck',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
        fistulaArmLocation: AccessLocation.neck.name,
      );

      final leftBp = await repository.recordBloodPressure(
        patientId: neckPatient.id,
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        armUsed: 'leftArm',
      );
      expect(leftBp.armUsed, equals('leftArm'));
      expect(leftBp.isSafeArm, isTrue);

      final rightBp = await repository.recordBloodPressure(
        patientId: neckPatient.id,
        systolic: 122,
        diastolic: 81,
        pulse: 74,
        armUsed: 'rightArm',
      );
      expect(rightBp.armUsed, equals('rightArm'));
      expect(rightBp.isSafeArm, isTrue);

      final thighPatient = await harness.createPatient(
        name: 'Bob Thigh',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.nonTunneledTemporaryDialysisLine.name,
        fistulaArmLocation: AccessLocation.thighGroin.name,
      );

      final thighLeftBp = await repository.recordBloodPressure(
        patientId: thighPatient.id,
        systolic: 118,
        diastolic: 78,
        pulse: 70,
        armUsed: 'leftArm',
      );
      expect(thighLeftBp.armUsed, equals('leftArm'));

      final thighRightBp = await repository.recordBloodPressure(
        patientId: thighPatient.id,
        systolic: 119,
        diastolic: 79,
        pulse: 71,
        armUsed: 'rightArm',
      );
      expect(thighRightBp.armUsed, equals('rightArm'));
    });

    test('Throws FistulaArmSafetyException when attempting to record BP on fistula-bearing arm', () async {
      final patient = await harness.createPatient(
        name: 'Jane Doe',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      expect(
        () => repository.recordBloodPressure(
          patientId: patient.id,
          systolic: 125,
          diastolic: 82,
          pulse: 72,
          armUsed: 'leftArm',
        ),
        throwsA(isA<FistulaArmSafetyException>()),
      );
    });

    test('Successfully records blood pressure on safe arm and persists in Drift SQLite with UUIDv4', () async {
      final patient = await harness.createPatient(
        name: 'Jane Doe',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      final record = await repository.recordBloodPressure(
        patientId: patient.id,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        armUsed: 'rightArm',
      );

      expect(record.id, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(record.id),
        isTrue,
      );
      expect(record.patientId, equals(patient.id));
      expect(record.systolic, equals(120));
      expect(record.diastolic, equals(80));
      expect(record.pulse, equals(70));
      expect(record.armUsed, equals('rightArm'));
      expect(record.isSafeArm, isTrue);
      expect(record.recordedAt, isNotNull);
      expect(record.createdAt, isNotNull);
      expect(record.updatedAt, isNotNull);

      // Verify stream surfaces the recorded blood pressure log
      final logs = await repository.watchBloodPressureLogs(patient.id).first;
      expect(logs.length, equals(1));
      expect(logs.first.id, equals(record.id));
      expect(logs.first.systolic, equals(120));
    });

    test('Preserves historical hemodynamic trends ordered by timestamp', () async {
      final patient = await harness.createPatient(
        name: 'Bob Ross',
        diagnosis: ClinicalCondition.nonDialysisCkd.name,
      );

      final t1 = DateTime.now().subtract(const Duration(hours: 2));
      final t2 = DateTime.now().subtract(const Duration(hours: 1));
      final t3 = DateTime.now();

      await repository.recordBloodPressure(
        patientId: patient.id,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        armUsed: 'rightArm',
        recordedAt: t1,
      );

      await repository.recordBloodPressure(
        patientId: patient.id,
        systolic: 125,
        diastolic: 80,
        pulse: 72,
        armUsed: 'leftArm',
        recordedAt: t2,
      );

      await repository.recordBloodPressure(
        patientId: patient.id,
        systolic: 118,
        diastolic: 78,
        pulse: 70,
        armUsed: 'rightArm',
        recordedAt: t3,
      );

      final trends = await repository.getHemodynamicTrends(patient.id);
      expect(trends.length, equals(3));
      // Ordered descending by recordedAt (most recent first)
      expect(trends[0].systolic, equals(118));
      expect(trends[1].systolic, equals(125));
      expect(trends[2].systolic, equals(130));
    });

    test('Paired Anti-Hypertensive BP Assessment: Baseline and Follow-Up with deltas and alarm scheduling', () async {
      final patient = await harness.createPatient(
        name: 'Hypertensive Patient',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      final med = await harness.createMedication(
        patientId: patient.id,
        name: 'Amlodipine',
        dosage: '10 mg',
        frequency: 'Daily',
        isAntiHypertensive: true,
      );

      final admin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: med.id,
      );

      // 1. Enforces Fistula Arm Safety Flag lockout on baseline measurement
      expect(
        () => repository.recordBaselineBloodPressure(
          patientId: patient.id,
          medicationAdministrationId: admin.id,
          medicationName: med.name,
          systolic: 165,
          diastolic: 100,
          pulse: 84,
          armUsed: 'leftArm', // Prohibited arm!
        ),
        throwsA(isA<FistulaArmSafetyException>()),
      );

      // 2. Records baseline on verified safe arm (rightArm)
      final baselineTime = DateTime.utc(2026, 9, 9, 10, 0, 0);
      final baseline = await repository.recordBaselineBloodPressure(
        patientId: patient.id,
        medicationAdministrationId: admin.id,
        medicationName: med.name,
        systolic: 165,
        diastolic: 100,
        pulse: 84,
        armUsed: 'rightArm',
        onsetWindowMinutes: 30,
        recordedAt: baselineTime,
      );

      expect(baseline.id, isNotEmpty);
      expect(baseline.isPairedAssessment, isTrue);
      expect(baseline.pairedRole, equals('baseline'));
      expect(baseline.pairedAssessmentId, isNotNull);
      expect(baseline.medicationAdministrationId, equals(admin.id));
      expect(baseline.systolic, equals(165));
      expect(baseline.diastolic, equals(100));
      expect(baseline.pulse, equals(84));
      expect(baseline.elapsedMinutes, isNull);
      expect(baseline.systolicDelta, isNull);

      // Verify alarm is scheduled for 30 minutes post-dose
      final alarmService = repository.alarmService;
      final alarm = alarmService.getAlarmForAssessment(baseline.pairedAssessmentId!);
      expect(alarm, isNotNull);
      expect(alarm!.intervalMinutes, equals(30));
      expect(alarm.scheduledFor, equals(baselineTime.add(const Duration(minutes: 30))));
      expect(alarm.medicationName, equals('Amlodipine'));

      // 3. Pending follow-ups query returns the pending baseline
      final pendingList = await repository.getPendingFollowUpAssessments(patient.id);
      expect(pendingList.length, equals(1));
      expect(pendingList.first.id, equals(baseline.id));

      // 4. Record follow-up measurement at 32 minutes post-dose
      final followUpTime = baselineTime.add(const Duration(minutes: 32));
      final followUp = await repository.recordFollowUpBloodPressure(
        patientId: patient.id,
        pairedAssessmentId: baseline.pairedAssessmentId!,
        systolic: 135,
        diastolic: 82,
        pulse: 76,
        armUsed: 'rightArm',
        recordedAt: followUpTime,
      );

      expect(followUp.id, isNotEmpty);
      expect(followUp.isPairedAssessment, isTrue);
      expect(followUp.pairedRole, equals('followUp'));
      expect(followUp.pairedAssessmentId, equals(baseline.pairedAssessmentId));
      expect(followUp.medicationAdministrationId, equals(admin.id));
      expect(followUp.systolic, equals(135));
      expect(followUp.diastolic, equals(82));
      expect(followUp.pulse, equals(76));

      // Verify calculated exact elapsed minutes and hemodynamic deltas
      expect(followUp.elapsedMinutes, equals(32));
      expect(followUp.systolicDelta, equals(-30)); // 135 - 165 = -30
      expect(followUp.diastolicDelta, equals(-18)); // 82 - 100 = -18
      expect(followUp.pulseDelta, equals(-8)); // 76 - 84 = -8

      // Verify alarm was marked completed/cancelled
      final alarmAfterFollowUp = alarmService.getAlarmForAssessment(baseline.pairedAssessmentId!);
      expect(alarmAfterFollowUp, isNull);

      // Verify pending follow-up list is now empty
      final pendingAfter = await repository.getPendingFollowUpAssessments(patient.id);
      expect(pendingAfter, isEmpty);

      // 5. Query paired assessments
      final pairedList = await repository.getPairedAssessments(patient.id);
      expect(pairedList.length, equals(1));
      expect(pairedList.first.baseline.id, equals(baseline.id));
      expect(pairedList.first.followUp?.id, equals(followUp.id));
      expect(pairedList.first.elapsedMinutes, equals(32));
      expect(pairedList.first.systolicDelta, equals(-30));

      // 6. Query paired assessment by medication administration ID
      final byAdmin = await repository.getPairedAssessmentForAdministration(admin.id);
      expect(byAdmin, isNotNull);
      expect(byAdmin!.baseline.id, equals(baseline.id));
      expect(byAdmin.followUp?.id, equals(followUp.id));
    });
  });
}
