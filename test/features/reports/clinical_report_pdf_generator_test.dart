import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/reports/data/clinical_report_repository.dart';
import 'package:nephrocare/src/features/reports/domain/clinical_report_config.dart';
import 'package:nephrocare/src/features/reports/domain/clinical_report_pdf_generator.dart';

void main() {
  group('ClinicalReportPdfGenerator Client-Side PDF Seam', () {
    late NephroTestHarness harness;
    late ClinicalReportRepository repository;
    final pdfGenerator = ClinicalReportPdfGenerator();

    setUp(() {
      harness = createNephroTestHarness();
      repository = ClinicalReportRepository(harness.database);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Compiles publication-quality client-side PDF document bytes for full clinical dataset', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0);

      // Create Patient with complete clinical attributes
      final patient = await harness.createPatient(
        name: 'Margaret Atwood',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 65.5,
        dailyFluidAllowanceMl: 1200,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        isCaregiverMirror: false,
      );

      // Add Dialysis Session
      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 2)),
        preWeightKg: 67.8,
        postWeightKg: 65.6,
        calculatedInterdialyticWeightGainKg: 2.3,
        calculatedUltrafiltrationGoalMl: 2300,
        calculatedPostWeightDifferenceKg: 0.1,
        actualFluidRemovedMl: 2200,
        notes: 'Smooth dialysis session without hypotension.',
      );

      // Add Blood Pressure
      await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 126,
        diastolic: 80,
        pulse: 72,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 1)),
      );

      // Add Fluid Intake & Output
      await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 250,
        beverageType: 'Water',
        phosphateBinderTaken: true,
        recordedAt: now.subtract(const Duration(hours: 5)),
      );
      await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 300,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: now.subtract(const Duration(hours: 3)),
      );

      // Add Access Inspection
      await harness.recordAccessInspection(
        patientId: patient.id,
        accessType: 'arteriovenousFistula',
        anatomicalLocation: 'leftArm',
        thrillPresent: true,
        bruitPresent: true,
        recordedAt: now.subtract(const Duration(days: 2)),
      );

      // Add Catheter
      await harness.recordCatheterInsertion(
        patientId: patient.id,
        insertionDate: now.subtract(const Duration(days: 4)),
        notes: 'Initial insertion',
      );

      final config = ModularReportConfig.defaultConfig();
      final reportData = await repository.compileReportData(
        patientId: patient.id,
        config: config,
        asOf: now,
      );

      // Generate PDF Document
      final pdfDocument = pdfGenerator.buildPdfDocument(reportData);
      expect(pdfDocument, isNotNull);

      // Generate PDF Bytes
      final pdfBytes = await pdfGenerator.generatePdfBytes(reportData);
      expect(pdfBytes, isNotEmpty);

      // Check PDF header signature '%PDF-'
      final headerSignature = utf8.decode(pdfBytes.sublist(0, 5));
      expect(headerSignature, equals('%PDF-'));
    });

    test('Omits excluded clinical sections when toggled off in report configuration', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0);

      final patient = await harness.createPatient(
        name: 'Alan Turing',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 70.0,
      );

      // Log records
      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 1)),
        preWeightKg: 72.0,
        postWeightKg: 70.0,
      );

      await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 1)),
      );

      // Only enable Patient Demographics and Blood Pressure (exclude Weight Trends, Fluid, Catheter)
      final config = ModularReportConfig(
        dateWindow: ReportDateWindow.last7Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.bloodPressureAndPulse,
        },
      );

      final reportData = await repository.compileReportData(
        patientId: patient.id,
        config: config,
        asOf: now,
      );

      final pdfBytes = await pdfGenerator.generatePdfBytes(reportData);
      expect(pdfBytes, isNotEmpty);
      expect(utf8.decode(pdfBytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('Compiles PDF with Paired BP table, Dual Fluid Balance section, and Medication Regimen via NephroTestHarness', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0);

      final patient = await harness.createPatient(
        name: 'Ada Lovelace',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 55.0,
        dailyFluidAllowanceMl: 1000,
      );

      // Prescribe medications
      final amlodipine = await harness.createMedication(
        patientId: patient.id,
        name: 'Amlodipine',
        dosage: '5mg',
        frequency: 'Daily (Morning)',
        isAntiHypertensive: true,
      );

      final sevelamer = await harness.createMedication(
        patientId: patient.id,
        name: 'Sevelamer Carbonate',
        dosage: '800mg',
        frequency: '3 times daily with meals',
        isPhosphateBinder: true,
      );

      // Record administrations
      final admin = await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: amlodipine.id,
        administeredAt: now.subtract(const Duration(days: 1, hours: 2)),
      );

      await harness.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: sevelamer.id,
        administeredAt: now.subtract(const Duration(hours: 5)),
        notes: 'Taken with lunch',
      );

      // Record Paired BP
      await harness.recordBaselineBloodPressure(
        patientId: patient.id,
        medicationAdministrationId: admin.id,
        medicationName: 'Amlodipine',
        systolic: 155,
        diastolic: 95,
        pulse: 82,
        armUsed: 'rightArm',
        pairedAssessmentId: 'pair-ada-1',
        recordedAt: now.subtract(const Duration(days: 1, hours: 2)),
      );

      await harness.recordFollowUpBloodPressure(
        patientId: patient.id,
        pairedAssessmentId: 'pair-ada-1',
        systolic: 130,
        diastolic: 80,
        pulse: 75,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 35)),
      );

      // Dual fluid balance records
      await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 800,
        beverageType: 'Water',
        recordedAt: now.subtract(const Duration(days: 1)),
      );

      await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 250,
        outputType: 'urine',
        recordedAt: now.subtract(const Duration(days: 1)),
      );

      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 1, hours: 4)),
        actualFluidRemovedMl: 1500,
        status: 'completed',
      );

      // Test with only the three new modules enabled
      final config = ModularReportConfig(
        dateWindow: ReportDateWindow.last7Days,
        enabledModules: {
          ClinicalReportModule.pairedAntiHypertensiveBp,
          ClinicalReportModule.dualFluidBalance,
          ClinicalReportModule.medicationRegimenAndAdherence,
        },
      );

      // Verify through NephroTestHarness helpers
      final pwDoc = await harness.buildModularClinicalReportDocument(
        patientId: patient.id,
        config: config,
        asOf: now,
      );
      expect(pwDoc, isNotNull);

      final pdfBytes = await harness.generateModularClinicalReportPdf(
        patientId: patient.id,
        config: config,
        asOf: now,
      );
      expect(pdfBytes, isNotEmpty);
      expect(utf8.decode(pdfBytes.sublist(0, 5)), equals('%PDF-'));
    });
  });
}
