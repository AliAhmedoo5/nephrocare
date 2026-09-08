import 'package:flutter/foundation.dart';

/// Observation date window options for Modular Clinical Report generation.
enum ReportDateWindow {
  last7Days('Last 7 Days', '7d', 7),
  last14Days('Last 14 Days', '14d', 14),
  last30Days('Last 30 Days', '30d', 30),
  custom('Custom Range', 'Custom', null);

  final String displayName;
  final String shortName;
  final int? defaultDays;

  const ReportDateWindow(this.displayName, this.shortName, this.defaultDays);
}

/// Clinical modules that can be individually included or excluded in the Modular Clinical Report.
enum ClinicalReportModule {
  patientDemographicsAndDiagnosis(
    'Patient Demographics & Diagnosis',
    'Core patient identifiers, primary diagnosis, and baseline clinical parameters.',
    Key('module_toggle_demographics'),
  ),
  weightTrends(
    'Weight Trends (Pre/Post/Prescribed Dry Weight)',
    'Hemodialysis pre-weight, post-weight, dry weight variances, and interdialytic weight gain.',
    Key('module_toggle_weight_trends'),
  ),
  bloodPressureAndPulse(
    'Blood Pressure & Pulse',
    'Hemodynamic monitoring records, arm-used tracking, and pulse trends.',
    Key('module_toggle_bp'),
  ),
  fluidBalanceAndIntake(
    '24-Hour Fluid Balance & Intake Logs',
    'Net fluid balances, allowance progression, beverage logs, and phosphate binder compliance.',
    Key('module_toggle_fluid'),
  ),
  accessInspectionAndCatheterHistory(
    'Access Inspection & Catheter Lifespan History',
    'Vascular access physical findings (thrill/bruit/infection) and Foley catheter 14-day cycle history.',
    Key('module_toggle_catheter'),
  );

  final String displayName;
  final String description;
  final Key widgetKey;

  const ClinicalReportModule(this.displayName, this.description, this.widgetKey);
}

/// Represents the resolved start and end date boundaries for a report window.
class DateWindowRange {
  final DateTime start;
  final DateTime end;

  const DateWindowRange({
    required this.start,
    required this.end,
  });

  /// The duration of the range represented in whole calendar days.
  int get durationInDays => end.difference(start).inDays;
}

/// Configuration specifying the date window and clinical modules for report generation.
class ModularReportConfig {
  final ReportDateWindow dateWindow;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Set<ClinicalReportModule> enabledModules;

  const ModularReportConfig({
    required this.dateWindow,
    this.customStartDate,
    this.customEndDate,
    required this.enabledModules,
  });

  /// Factory constructor creating the default configuration:
  /// 14-day observation window with all 5 clinical modules enabled.
  factory ModularReportConfig.defaultConfig() {
    return const ModularReportConfig(
      dateWindow: ReportDateWindow.last14Days,
      enabledModules: {
        ClinicalReportModule.patientDemographicsAndDiagnosis,
        ClinicalReportModule.weightTrends,
        ClinicalReportModule.bloodPressureAndPulse,
        ClinicalReportModule.fluidBalanceAndIntake,
        ClinicalReportModule.accessInspectionAndCatheterHistory,
      },
    );
  }

  /// Whether a specific clinical module is currently included in the report.
  bool isModuleEnabled(ClinicalReportModule module) => enabledModules.contains(module);

  /// Toggles inclusion of a given clinical module, returning an updated configuration.
  ModularReportConfig toggleModule(ClinicalReportModule module, bool enabled) {
    final updated = Set<ClinicalReportModule>.from(enabledModules);
    if (enabled) {
      updated.add(module);
    } else {
      updated.remove(module);
    }
    return copyWith(enabledModules: updated);
  }

  /// Resolves the absolute date boundaries based on the configured date window.
  DateWindowRange resolveDateRange({DateTime? asOf}) {
    final reference = (asOf ?? DateTime.now()).toUtc();

    if (dateWindow == ReportDateWindow.custom) {
      DateTime start = (customStartDate ?? reference.subtract(const Duration(days: 7))).toUtc();
      DateTime end = (customEndDate ?? reference).toUtc();

      // If end date has no specific time component (e.g. midnight from DatePicker), expand through end of day
      if (end.hour == 0 && end.minute == 0 && end.second == 0 && end.millisecond == 0) {
        end = DateTime.utc(end.year, end.month, end.day, 23, 59, 59, 999);
      }

      if (start.isAfter(end)) {
        throw ArgumentError('Custom start date ($start) cannot be after end date ($end).');
      }

      return DateWindowRange(start: start, end: end);
    }

    final days = dateWindow.defaultDays ?? 14;
    final start = reference.subtract(Duration(days: days));
    return DateWindowRange(start: start, end: reference);
  }

  ModularReportConfig copyWith({
    ReportDateWindow? dateWindow,
    DateTime? customStartDate,
    DateTime? customEndDate,
    Set<ClinicalReportModule>? enabledModules,
  }) {
    return ModularReportConfig(
      dateWindow: dateWindow ?? this.dateWindow,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      enabledModules: enabledModules ?? this.enabledModules,
    );
  }
}
