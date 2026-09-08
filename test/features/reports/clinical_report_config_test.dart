import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/reports/domain/clinical_report_config.dart';

void main() {
  group('ClinicalReportConfig & Date Window Calculation Seam', () {
    final asOf = DateTime.utc(2026, 9, 9, 12, 0);

    test('Default config includes all 5 clinical modules and defaults to 14 days', () {
      final config = ModularReportConfig.defaultConfig();

      expect(config.dateWindow, equals(ReportDateWindow.last14Days));
      expect(config.enabledModules.length, equals(5));
      expect(config.isModuleEnabled(ClinicalReportModule.patientDemographicsAndDiagnosis), isTrue);
      expect(config.isModuleEnabled(ClinicalReportModule.weightTrends), isTrue);
      expect(config.isModuleEnabled(ClinicalReportModule.bloodPressureAndPulse), isTrue);
      expect(config.isModuleEnabled(ClinicalReportModule.fluidBalanceAndIntake), isTrue);
      expect(config.isModuleEnabled(ClinicalReportModule.accessInspectionAndCatheterHistory), isTrue);
    });

    test('Resolves 7-day, 14-day, and 30-day observation date windows accurately', () {
      // 7 Days
      final config7 = ModularReportConfig(
        dateWindow: ReportDateWindow.last7Days,
        enabledModules: {ClinicalReportModule.patientDemographicsAndDiagnosis},
      );
      final range7 = config7.resolveDateRange(asOf: asOf);
      expect(range7.start, equals(DateTime.utc(2026, 9, 2, 12, 0)));
      expect(range7.end, equals(asOf));
      expect(range7.durationInDays, equals(7));

      // 14 Days
      final config14 = ModularReportConfig(
        dateWindow: ReportDateWindow.last14Days,
        enabledModules: {ClinicalReportModule.patientDemographicsAndDiagnosis},
      );
      final range14 = config14.resolveDateRange(asOf: asOf);
      expect(range14.start, equals(DateTime.utc(2026, 8, 26, 12, 0)));
      expect(range14.end, equals(asOf));
      expect(range14.durationInDays, equals(14));

      // 30 Days
      final config30 = ModularReportConfig(
        dateWindow: ReportDateWindow.last30Days,
        enabledModules: {ClinicalReportModule.patientDemographicsAndDiagnosis},
      );
      final range30 = config30.resolveDateRange(asOf: asOf);
      expect(range30.start, equals(DateTime.utc(2026, 8, 10, 12, 0)));
      expect(range30.end, equals(asOf));
      expect(range30.durationInDays, equals(30));
    });

    test('Resolves custom date window with specific start and end boundaries', () {
      final customStart = DateTime.utc(2026, 8, 1, 0, 0);
      final customEnd = DateTime.utc(2026, 8, 15, 23, 59);

      final customConfig = ModularReportConfig(
        dateWindow: ReportDateWindow.custom,
        customStartDate: customStart,
        customEndDate: customEnd,
        enabledModules: {ClinicalReportModule.weightTrends},
      );

      final range = customConfig.resolveDateRange(asOf: asOf);
      expect(range.start, equals(customStart));
      expect(range.end, equals(customEnd));
    });

    test('Toggling modules individually with copyWith updates configuration', () {
      var config = ModularReportConfig.defaultConfig();
      expect(config.isModuleEnabled(ClinicalReportModule.weightTrends), isTrue);

      // Disable weightTrends
      config = config.toggleModule(ClinicalReportModule.weightTrends, false);
      expect(config.isModuleEnabled(ClinicalReportModule.weightTrends), isFalse);
      expect(config.enabledModules.contains(ClinicalReportModule.weightTrends), isFalse);

      // Enable weightTrends back
      config = config.toggleModule(ClinicalReportModule.weightTrends, true);
      expect(config.isModuleEnabled(ClinicalReportModule.weightTrends), isTrue);
    });

    test('Custom date window validation prevents inverted date ranges', () {
      final invalidConfig = ModularReportConfig(
        dateWindow: ReportDateWindow.custom,
        customStartDate: DateTime.utc(2026, 9, 10),
        customEndDate: DateTime.utc(2026, 9, 1),
        enabledModules: {ClinicalReportModule.patientDemographicsAndDiagnosis},
      );

      expect(() => invalidConfig.resolveDateRange(), throwsArgumentError);
    });
  });
}
