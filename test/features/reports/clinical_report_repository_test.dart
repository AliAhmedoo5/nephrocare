import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/reports/data/clinical_report_repository.dart';
import 'package:nephrocare/src/features/reports/domain/clinical_report_config.dart';

void main() {
  group('ClinicalReportRepository Data Aggregation Seam', () {
    late NephroTestHarness harness;
    late ClinicalReportRepository repository;

    setUp(() {
      harness = createNephroTestHarness();
      repository = ClinicalReportRepository(harness.database);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Aggregates full clinical dataset across all 5 enabled modules within date window', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0);

      // 1. Create Patient
      final patient = await harness.createPatient(
        name: 'Robert Langdon',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 72.0,
        dailyFluidAllowanceMl: 1500,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
      );

      // 2. Add Dialysis Session within 7 days
      final sessionInWindow = await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 3)),
        preWeightKg: 74.2,
        postWeightKg: 72.1,
        calculatedInterdialyticWeightGainKg: 2.2,
        calculatedUltrafiltrationGoalMl: 2200,
        actualFluidRemovedMl: 2100,
      );

      // Add Dialysis Session OUTSIDE 7 days (e.g., 20 days ago)
      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 20)),
        preWeightKg: 75.0,
        postWeightKg: 72.0,
      );

      // 3. Add Blood Pressure Logs: 1 in window, 1 outside window
      final bpInWindow = await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 128,
        diastolic: 82,
        pulse: 74,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 2)),
      );
      await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 150,
        diastolic: 95,
        pulse: 88,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 25)),
      );

      // 4. Add Fluid Intake and Output: in window and outside window
      final intakeInWindow = await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 300,
        beverageType: 'Water',
        phosphateBinderTaken: true,
        recordedAt: now.subtract(const Duration(days: 1)),
      );
      await harness.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 500,
        beverageType: 'Juice',
        recordedAt: now.subtract(const Duration(days: 15)),
      );

      final outputInWindow = await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 400,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: now.subtract(const Duration(days: 1)),
      );
      await harness.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 600,
        outputType: 'urine',
        recordedAt: now.subtract(const Duration(days: 16)),
      );

      // 5. Add Access Inspection in window
      final inspectionInWindow = await harness.recordAccessInspection(
        patientId: patient.id,
        accessType: 'arteriovenousFistula',
        anatomicalLocation: 'leftArm',
        thrillPresent: true,
        bruitPresent: true,
        recordedAt: now.subtract(const Duration(days: 4)),
      );

      // 6. Add Catheter Event
      final catheterInWindow = await harness.recordCatheterInsertion(
        patientId: patient.id,
        insertionDate: now.subtract(const Duration(days: 5)),
        notes: 'Clinical catheter insertion',
      );

      // Compile 7-day report with all modules enabled
      final config = ModularReportConfig(
        dateWindow: ReportDateWindow.last7Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.weightTrends,
          ClinicalReportModule.bloodPressureAndPulse,
          ClinicalReportModule.fluidBalanceAndIntake,
          ClinicalReportModule.accessInspectionAndCatheterHistory,
        },
      );

      final reportData = await repository.compileReportData(
        patientId: patient.id,
        config: config,
        asOf: now,
      );

      expect(reportData.patient.id, equals(patient.id));
      expect(reportData.patient.name, equals('Robert Langdon'));
      expect(reportData.dateRange.durationInDays, equals(7));

      // Weight Trends: Only 1 session in window
      expect(reportData.dialysisSessions.length, equals(1));
      expect(reportData.dialysisSessions.first.id, equals(sessionInWindow.id));

      // Blood Pressure: Only 1 in window
      expect(reportData.bloodPressureLogs.length, equals(1));
      expect(reportData.bloodPressureLogs.first.id, equals(bpInWindow.id));

      // Fluid: Only logs in window
      expect(reportData.fluidIntakeLogs.length, equals(1));
      expect(reportData.fluidIntakeLogs.first.id, equals(intakeInWindow.id));
      expect(reportData.fluidOutputLogs.length, equals(1));
      expect(reportData.fluidOutputLogs.first.id, equals(outputInWindow.id));
      expect(reportData.fluidBalanceSummary, isNotNull);

      // Access & Catheter: Only in window
      expect(reportData.accessInspections.length, equals(1));
      expect(reportData.accessInspections.first.id, equals(inspectionInWindow.id));
      expect(reportData.catheterEvents.length, equals(1));
      expect(reportData.catheterEvents.first.id, equals(catheterInWindow.id));
      expect(reportData.catheterLifespanSummary, isNotNull);
    });

    test('Omits data for excluded clinical modules even if database records exist', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0);

      final patient = await harness.createPatient(
        name: 'Arthur Conan',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 68.0,
      );

      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: now.subtract(const Duration(days: 1)),
        preWeightKg: 70.0,
        postWeightKg: 68.0,
      );

      await harness.recordBloodPressure(
        patientId: patient.id,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        armUsed: 'rightArm',
        recordedAt: now.subtract(const Duration(days: 1)),
      );

      // Config excluding Weight Trends and Blood Pressure
      final config = ModularReportConfig(
        dateWindow: ReportDateWindow.last7Days,
        enabledModules: {
          ClinicalReportModule.patientDemographicsAndDiagnosis,
          ClinicalReportModule.fluidBalanceAndIntake,
        },
      );

      final reportData = await repository.compileReportData(
        patientId: patient.id,
        config: config,
        asOf: now,
      );

      expect(reportData.dialysisSessions, isEmpty);
      expect(reportData.bloodPressureLogs, isEmpty);
      expect(reportData.accessInspections, isEmpty);
      expect(reportData.catheterEvents, isEmpty);
    });
  });
}
