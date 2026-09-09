import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';
import 'package:nephrocare/src/features/profile/domain/condition_adaptive_grid_config.dart';
import 'package:nephrocare/src/features/profile/data/patient_repository.dart';

void main() {
  group('Domain/State Seam: Patient Profile Persistence & Invariants', () {
    late NephroTestHarness harness;
    late PatientRepository repository;

    setUp(() {
      harness = createNephroTestHarness();
      repository = PatientRepository(harness.database);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Creates patient profile with UUIDv4, timestamps, and vascular access details', () async {
      final patient = await repository.createPatientProfile(
        name: 'Eleanor Vance',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 68.5,
        dailyFluidAllowanceMl: 1200,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
      );

      expect(patient.id, isNotEmpty);
      // Validates UUIDv4 format
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false)
            .hasMatch(patient.id),
        isTrue,
      );
      expect(patient.name, equals('Eleanor Vance'));
      expect(patient.diagnosis, equals('hemodialysis'));
      expect(patient.prescribedDryWeightKg, equals(68.5));
      expect(patient.dailyFluidAllowanceMl, equals(1200));
      expect(patient.vascularAccessType, equals('arteriovenousFistula'));
      expect(patient.fistulaArmLocation, equals('leftArm'));
      expect(patient.createdAt, isNotNull);
      expect(patient.updatedAt, isNotNull);

      // Verify active patient stream emits the created patient
      final activePatient = await repository.watchActivePatient().first;
      expect(activePatient?.id, equals(patient.id));
      expect(activePatient?.name, equals('Eleanor Vance'));
      expect(activePatient?.isCaregiverMirror, isFalse);
    });

    test('Creates Caregiver Mirror profile and verifies isCaregiverMirror flag', () async {
      final mirrorProfile = await repository.createPatientProfile(
        name: 'Grandpa Joe',
        diagnosis: ClinicalCondition.peritonealDialysis.name,
        prescribedDryWeightKg: 74.0,
        dailyFluidAllowanceMl: 1500,
        isCaregiverMirror: true,
      );

      expect(mirrorProfile.id, isNotEmpty);
      expect(mirrorProfile.name, equals('Grandpa Joe'));
      expect(mirrorProfile.isCaregiverMirror, isTrue);

      final fetched = await repository.getPatientById(mirrorProfile.id);
      expect(fetched, isNotNull);
      expect(fetched!.isCaregiverMirror, isTrue);
    });

    test('Supports multi-patient profiles, retrieving all profiles, and switching active patient', () async {
      final now = DateTime.now().toUtc();

      // 1. Create initial direct patient profile
      final patient1 = await repository.createPatientProfile(
        name: 'Eleanor Vance',
        diagnosis: ClinicalCondition.hemodialysis.name,
        prescribedDryWeightKg: 68.5,
        dailyFluidAllowanceMl: 1200,
        isCaregiverMirror: false,
        createdAt: now.subtract(const Duration(seconds: 10)),
        updatedAt: now.subtract(const Duration(seconds: 10)),
      );

      // 2. Create second profile as Caregiver Mirror
      final patient2 = await repository.createPatientProfile(
        name: 'Marcus Chen',
        diagnosis: ClinicalCondition.urologicalCatheter.name,
        dailyFluidAllowanceMl: 2000,
        isCaregiverMirror: true,
        createdAt: now.subtract(const Duration(seconds: 5)),
        updatedAt: now.subtract(const Duration(seconds: 5)),
      );

      // Verify getAllPatients returns both profiles
      final allPatients = await repository.getAllPatients();
      expect(allPatients.length, equals(2));
      expect(allPatients.map((p) => p.name).toList(), containsAll(['Eleanor Vance', 'Marcus Chen']));

      // Latest created profile is currently active by default
      final initialActive = await repository.getActivePatient();
      expect(initialActive?.id, equals(patient2.id));

      // 3. Switch active patient back to Patient 1
      await repository.setActivePatient(patient1.id, asOf: now.subtract(const Duration(seconds: 2)));

      final switchedActive = await repository.getActivePatient();
      expect(switchedActive?.id, equals(patient1.id));
      expect(switchedActive?.name, equals('Eleanor Vance'));
      expect(switchedActive?.isCaregiverMirror, isFalse);

      // 4. Switch active patient to Patient 2 (Caregiver Mirror)
      await repository.setActivePatient(patient2.id, asOf: now);

      final switchedMirror = await repository.getActivePatient();
      expect(switchedMirror?.id, equals(patient2.id));
      expect(switchedMirror?.name, equals('Marcus Chen'));
      expect(switchedMirror?.isCaregiverMirror, isTrue);

      // 5. Verify reactive stream watchAllPatients emits full list
      final streamList = await repository.watchAllPatients().first;
      expect(streamList.length, equals(2));
    });
  });

  group('Domain/State Seam: Condition-Adaptive Grid 6-Card Mapping', () {
    test('Hemodialysis condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.hemodialysis.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Unified Dialysis Session'));
      expect(titles, contains('Blood Pressure & Paired BP'));
      expect(titles, contains('Fluid Hub'));
      expect(titles, contains('Medication Management'));
      expect(titles, contains('Catheter & Access Monitor'));
      expect(titles, contains('Modular Clinical Report'));
    });

    test('Peritoneal Dialysis condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.peritonealDialysis.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Exchange Log'));
      expect(titles, contains('Exit-Site Inspection'));
      expect(titles, contains('Daily Weight'));
      expect(titles, contains('Blood Pressure'));
      expect(titles, contains('Fluid Hub'));
      expect(titles, contains('Medication Management'));
    });

    test('Non-Dialysis CKD condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.nonDialysisCkd.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Blood Pressure & Paired BP'));
      expect(titles, contains('Daily Weight'));
      expect(titles, contains('Fluid Hub'));
      expect(titles, contains('Medication Management'));
      expect(titles, contains('Symptom Log'));
      expect(titles, contains('Modular Clinical Report'));
    });

    test('Urological / Catheter condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.urologicalCatheter.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Foley Catheter Lifespan'));
      expect(titles, contains('Fluid Hub'));
      expect(titles, contains('Medication Management'));
      expect(titles, contains('Blood Pressure'));
      expect(titles, contains('Symptom Log'));
      expect(titles, contains('Modular Clinical Report'));
    });

    test('All cards have non-empty ID, title, subtitle, icon, and semantic label', () {
      for (final condition in ClinicalCondition.values) {
        final cards = ConditionAdaptiveGridConfig.getCardsForCondition(condition.name);
        expect(cards.length, equals(6));
        for (final card in cards) {
          expect(card.id, isNotEmpty);
          expect(card.title, isNotEmpty);
          expect(card.subtitle, isNotEmpty);
          expect(card.semanticLabel, isNotEmpty);
        }
      }
    });
  });
}
