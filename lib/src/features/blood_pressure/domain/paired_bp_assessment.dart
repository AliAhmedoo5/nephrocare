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
}

/// Constants defining clinical roles within a paired blood pressure assessment.
abstract final class PairedAssessmentRole {
  static const String baseline = 'baseline';
  static const String followUp = 'followUp';
}

