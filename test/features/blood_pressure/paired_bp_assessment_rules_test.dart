import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/blood_pressure/domain/paired_bp_assessment_rules.dart';

void main() {
  group('Domain Seam: PairedBpAssessmentRules', () {
    test('Configurable pharmacological onset window defaults to 30 minutes and validates 20-35 min range', () {
      expect(PairedBpAssessmentRules.defaultOnsetWindowMinutes, equals(30));
      expect(PairedBpAssessmentRules.minOnsetWindowMinutes, equals(20));
      expect(PairedBpAssessmentRules.maxOnsetWindowMinutes, equals(35));

      expect(PairedBpAssessmentRules.isValidOnsetWindow(30), isTrue);
      expect(PairedBpAssessmentRules.isValidOnsetWindow(20), isTrue);
      expect(PairedBpAssessmentRules.isValidOnsetWindow(35), isTrue);
      expect(PairedBpAssessmentRules.isValidOnsetWindow(15), isFalse);
      expect(PairedBpAssessmentRules.isValidOnsetWindow(40), isFalse);

      expect(PairedBpAssessmentRules.clampOnsetWindow(15), equals(20));
      expect(PairedBpAssessmentRules.clampOnsetWindow(45), equals(35));
      expect(PairedBpAssessmentRules.clampOnsetWindow(25), equals(25));
    });

    test('Calculates exact elapsed minutes between baseline and follow-up timestamps', () {
      final baseline = DateTime.utc(2026, 9, 9, 14, 0, 0);
      final followUp = DateTime.utc(2026, 9, 9, 14, 31, 45);

      final elapsed = PairedBpAssessmentRules.calculateElapsedMinutes(
        baselineTime: baseline,
        followUpTime: followUp,
      );

      expect(elapsed, equals(31));
    });

    test('Calculates systolic, diastolic, and pulse deltas relative to baseline', () {
      final deltas = PairedBpAssessmentRules.calculateDeltas(
        baselineSystolic: 160,
        baselineDiastolic: 95,
        baselinePulse: 84,
        followUpSystolic: 135,
        followUpDiastolic: 82,
        followUpPulse: 76,
      );

      expect(deltas.systolicDelta, equals(-25));
      expect(deltas.diastolicDelta, equals(-13));
      expect(deltas.pulseDelta, equals(-8));
    });

    test('Provides clinical hemodynamic response evaluation string', () {
      final deltas = PairedBpAssessmentRules.calculateDeltas(
        baselineSystolic: 155,
        baselineDiastolic: 95,
        baselinePulse: 80,
        followUpSystolic: 130,
        followUpDiastolic: 80,
        followUpPulse: 75,
      );

      final summary = PairedBpAssessmentRules.formatDeltasSummary(deltas);
      expect(summary, contains('Systolic: -25 mmHg'));
      expect(summary, contains('Diastolic: -15 mmHg'));
      expect(summary, contains('Pulse: -5 bpm'));
    });
  });
}
