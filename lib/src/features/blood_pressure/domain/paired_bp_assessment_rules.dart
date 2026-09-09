/// Hemodynamic difference values between post-dose follow-up and baseline measurements.
class HemodynamicDeltas {
  final int systolicDelta;
  final int diastolicDelta;
  final int pulseDelta;

  const HemodynamicDeltas({
    required this.systolicDelta,
    required this.diastolicDelta,
    required this.pulseDelta,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HemodynamicDeltas &&
          runtimeType == other.runtimeType &&
          systolicDelta == other.systolicDelta &&
          diastolicDelta == other.diastolicDelta &&
          pulseDelta == other.pulseDelta;

  @override
  int get hashCode => Object.hash(systolicDelta, diastolicDelta, pulseDelta);

  @override
  String toString() =>
      'HemodynamicDeltas(systolicDelta: $systolicDelta, diastolicDelta: $diastolicDelta, pulseDelta: $pulseDelta)';
}

/// Clinical rules and calculations for Paired Anti-Hypertensive Blood Pressure Assessment
/// per CONTEXT.md and ADR-0005.
class PairedBpAssessmentRules {
  /// Default pharmacological onset window in minutes (30 min).
  static const int defaultOnsetWindowMinutes = 30;

  /// Minimum permitted pharmacological onset window in minutes (20 min).
  static const int minOnsetWindowMinutes = 20;

  /// Maximum permitted pharmacological onset window in minutes (35 min).
  static const int maxOnsetWindowMinutes = 35;

  /// Validates whether the onset window duration is within the clinical range (20–35 min).
  static bool isValidOnsetWindow(int minutes) {
    return minutes >= minOnsetWindowMinutes && minutes <= maxOnsetWindowMinutes;
  }

  /// Clamps the onset window to the acceptable clinical interval (20–35 min).
  static int clampOnsetWindow(int minutes) {
    if (minutes < minOnsetWindowMinutes) return minOnsetWindowMinutes;
    if (minutes > maxOnsetWindowMinutes) return maxOnsetWindowMinutes;
    return minutes;
  }

  /// Calculates exact elapsed minutes between baseline and follow-up measurement timestamps.
  static int calculateElapsedMinutes({
    required DateTime baselineTime,
    required DateTime followUpTime,
  }) {
    final diff = followUpTime.difference(baselineTime);
    return diff.inMinutes;
  }

  /// Calculates hemodynamic deltas (follow-up minus baseline).
  ///
  /// A negative delta indicates a drop in blood pressure or pulse following medication administration.
  static HemodynamicDeltas calculateDeltas({
    required int baselineSystolic,
    required int baselineDiastolic,
    required int baselinePulse,
    required int followUpSystolic,
    required int followUpDiastolic,
    required int followUpPulse,
  }) {
    return HemodynamicDeltas(
      systolicDelta: followUpSystolic - baselineSystolic,
      diastolicDelta: followUpDiastolic - baselineDiastolic,
      pulseDelta: followUpPulse - baselinePulse,
    );
  }

  /// Formats hemodynamic deltas into a plain-language clinical summary.
  static String formatDeltasSummary(HemodynamicDeltas deltas) {
    final sysSign = deltas.systolicDelta > 0 ? '+' : '';
    final diaSign = deltas.diastolicDelta > 0 ? '+' : '';
    final pulseSign = deltas.pulseDelta > 0 ? '+' : '';

    return 'Systolic: $sysSign${deltas.systolicDelta} mmHg, '
        'Diastolic: $diaSign${deltas.diastolicDelta} mmHg, '
        'Pulse: $pulseSign${deltas.pulseDelta} bpm';
  }
}
