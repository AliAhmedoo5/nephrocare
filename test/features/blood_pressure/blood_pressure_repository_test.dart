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

    test('Identifies safe arm and prohibited arm correctly per ADR-0003', () async {
      final fistulaPatient = await harness.createPatient(
        name: 'Jane Doe',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.arteriovenousFistula.name,
        fistulaArmLocation: AccessLocation.leftArm.name,
      );

      expect(VascularSafetyRules.hasArmAccess(fistulaPatient), isTrue);
      expect(VascularSafetyRules.getProhibitedArm(fistulaPatient), equals('leftArm'));
      expect(VascularSafetyRules.getSafeArm(fistulaPatient), equals('rightArm'));
      expect(VascularSafetyRules.isArmSafe(patient: fistulaPatient, arm: 'leftArm'), isFalse);
      expect(VascularSafetyRules.isArmSafe(patient: fistulaPatient, arm: 'rightArm'), isTrue);

      final nonArmPatient = await harness.createPatient(
        name: 'John Smith',
        diagnosis: ClinicalCondition.hemodialysis.name,
        vascularAccessType: VascularAccessType.dialysisCentralLine.name,
        fistulaArmLocation: AccessLocation.chest.name,
      );

      expect(VascularSafetyRules.hasArmAccess(nonArmPatient), isFalse);
      expect(VascularSafetyRules.getProhibitedArm(nonArmPatient), isNull);
      expect(VascularSafetyRules.isArmSafe(patient: nonArmPatient, arm: 'leftArm'), isTrue);
      expect(VascularSafetyRules.isArmSafe(patient: nonArmPatient, arm: 'rightArm'), isTrue);
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
  });
}
