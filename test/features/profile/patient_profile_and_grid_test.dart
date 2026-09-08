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
    });
  });

  group('Domain/State Seam: Condition-Adaptive Grid 6-Card Mapping', () {
    test('Hemodialysis condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.hemodialysis.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Check-in'));
      expect(titles, contains('Post-Dialysis Log'));
      expect(titles, contains('Blood Pressure'));
      expect(titles, contains('Fluid Intake & Binders'));
      expect(titles, contains('Fluid Output'));
      expect(titles, contains('Modular Clinical Report'));
    });

    test('Peritoneal Dialysis condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.peritonealDialysis.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Exchange Log'));
      expect(titles, contains('Exit-Site Inspection'));
      expect(titles, contains('Daily Weight & Dry Weight'));
      expect(titles, contains('Blood Pressure'));
      expect(titles, contains('24h Fluid Balance'));
      expect(titles, contains('Modular Clinical Report'));
    });

    test('Non-Dialysis CKD condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.nonDialysisCkd.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Blood Pressure'));
      expect(titles, contains('Daily Weight'));
      expect(titles, contains('Fluid Allowance Tracker'));
      expect(titles, contains('Medication & Binders'));
      expect(titles, contains('Symptom Log'));
      expect(titles, contains('Modular Clinical Report'));
    });

    test('Urological / Catheter condition maps to exactly 6 clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.urologicalCatheter.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles, contains('Foley Catheter Lifespan'));
      expect(titles, contains('Urine Evacuation'));
      expect(titles, contains('Fluid Intake'));
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
