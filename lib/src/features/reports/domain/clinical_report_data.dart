import '../../../core/database/app_database.dart';
import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../fluid/domain/fluid_balance_summary.dart';
import 'clinical_report_config.dart';

/// Aggregated domain data container representing the clinical dataset
/// for a Modular Clinical Report across the selected observation date window.
class ClinicalReportData {
  final Patient patient;
  final ModularReportConfig config;
  final DateWindowRange dateRange;
  final DateTime generatedAt;
  final List<DialysisSession> dialysisSessions;
  final List<BloodPressureLog> bloodPressureLogs;
  final List<FluidIntakeLog> fluidIntakeLogs;
  final List<FluidOutputLog> fluidOutputLogs;
  final FluidBalanceSummary? fluidBalanceSummary;
  final List<AccessInspection> accessInspections;
  final List<CatheterEvent> catheterEvents;
  final CatheterLifespanSummary? catheterLifespanSummary;

  const ClinicalReportData({
    required this.patient,
    required this.config,
    required this.dateRange,
    required this.generatedAt,
    this.dialysisSessions = const [],
    this.bloodPressureLogs = const [],
    this.fluidIntakeLogs = const [],
    this.fluidOutputLogs = const [],
    this.fluidBalanceSummary,
    this.accessInspections = const [],
    this.catheterEvents = const [],
    this.catheterLifespanSummary,
  });
}
