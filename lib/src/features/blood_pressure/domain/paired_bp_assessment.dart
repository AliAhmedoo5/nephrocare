import '../../../core/database/app_database.dart';

/// Clinical aggregate uniting a baseline blood pressure measurement and its corresponding
/// follow-up reading recorded 20–35 minutes after anti-hypertensive administration.
class PairedBpAssessment {
  final BloodPressureLog baseline;
  final BloodPressureLog? followUp;
  final String? medicationAdministrationId;

  const PairedBpAssessment({
    required this.baseline,
    this.followUp,
    this.medicationAdministrationId,
  });

  String get pairedAssessmentId => baseline.pairedAssessmentId ?? baseline.id;
  bool get isCompleted => followUp != null;
  int? get elapsedMinutes => followUp?.elapsedMinutes;
  int? get systolicDelta => followUp?.systolicDelta;
  int? get diastolicDelta => followUp?.diastolicDelta;
  int? get pulseDelta => followUp?.pulseDelta;

  @override
  String toString() =>
      'PairedBpAssessment(pairedAssessmentId: $pairedAssessmentId, baseline: ${baseline.systolic}/${baseline.diastolic}, followUp: ${followUp != null ? '${followUp!.systolic}/${followUp!.diastolic}' : 'pending'}, elapsedMinutes: $elapsedMinutes)';

  /// Groups paired baseline and follow-up blood pressure logs into [PairedBpAssessment] models.
  static List<PairedBpAssessment> groupFromLogs(List<BloodPressureLog> logs) {
    final Map<String, BloodPressureLog> baselines = {};
    final Map<String, BloodPressureLog> followUps = {};

    for (final log in logs) {
      final pairId = log.pairedAssessmentId ?? log.id;
      if (log.pairedRole == PairedAssessmentRole.baseline) {
        baselines[pairId] = log;
      } else if (log.pairedRole == PairedAssessmentRole.followUp) {
        followUps[pairId] = log;
      }
    }

    final List<PairedBpAssessment> pairs = [];
    for (final entry in baselines.entries) {
      pairs.add(
        PairedBpAssessment(
          baseline: entry.value,
          followUp: followUps[entry.key],
          medicationAdministrationId: entry.value.medicationAdministrationId,
        ),
      );
    }

    pairs.sort((a, b) => b.baseline.recordedAt.compareTo(a.baseline.recordedAt));
    return pairs;
  }
}

/// Constants defining clinical roles within a paired blood pressure assessment.
abstract final class PairedAssessmentRole {
  static const String baseline = 'baseline';
  static const String followUp = 'followUp';
}

