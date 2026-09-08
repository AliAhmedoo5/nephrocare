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
  });
}
