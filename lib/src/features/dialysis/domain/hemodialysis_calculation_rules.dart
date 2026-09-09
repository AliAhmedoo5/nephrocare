import 'dart:math' as math;
import '../../profile/domain/clinical_condition.dart';

/// Clinical calculations and safety validation rules for Hemodialysis sessions.
class HemodialysisCalculationRules {
  /// Calculates Interdialytic Weight Gain (IDWG).
  ///
  /// Per CONTEXT.md, Interdialytic Weight Gain is the fluid weight accumulated
  /// between the end of one dialysis session and the start of the next.
  /// If previous session post-weight is available, IDWG = currentPreWeight - previousPostWeight.
  /// If no previous session exists, falls back to difference against Prescribed Dry Weight:
  /// currentPreWeight - prescribedDryWeight.
  static double calculateInterdialyticWeightGain({
    required double currentPreWeightKg,
    double? previousPostWeightKg,
    double? prescribedDryWeightKg,
  }) {
    double rawGain;
    if (previousPostWeightKg != null) {
      rawGain = currentPreWeightKg - previousPostWeightKg;
    } else if (prescribedDryWeightKg != null) {
      rawGain = currentPreWeightKg - prescribedDryWeightKg;
    } else {
      rawGain = 0.0;
    }

    return double.parse(rawGain.toStringAsFixed(2));
  }

  /// Calculates the Ultrafiltration Goal in milliliters (mL).
  ///
  /// Per CONTEXT.md, the Ultrafiltration Goal is the target volume of fluid to be
  /// extracted during a hemodialysis treatment to return the patient to Prescribed Dry Weight.
  /// 1 kg fluid removal = 1000 mL.
  /// Additional volume allowances (such as prime/rinseback fluid or oral consumption allowance)
  /// are added to the goal.
  /// If patient is already at or below Prescribed Dry Weight, baseline fluid removal is 0.
  static int calculateUltrafiltrationGoal({
    required double currentPreWeightKg,
    required double prescribedDryWeightKg,
    int volumeAllowanceMl = 0,
  }) {
    final weightDifferenceKg = currentPreWeightKg - prescribedDryWeightKg;
    if (weightDifferenceKg <= 0) {
      return math.max(0, volumeAllowanceMl);
    }

    final baselineFluidMl = (weightDifferenceKg * 1000).round();
    return baselineFluidMl + volumeAllowanceMl;
  }

  /// Calculates difference between post-dialysis weight and Prescribed Dry Weight in kg.
  /// Positive value indicates remaining fluid overload; negative value indicates below dry weight.
  static double calculatePostWeightDifference({
    required double postWeightKg,
    required double prescribedDryWeightKg,
  }) {
    final diff = postWeightKg - prescribedDryWeightKg;
    return double.parse(diff.toStringAsFixed(2));
  }

  /// Evaluates access inspection criteria and returns any clinical safety warning messages.
  ///
  /// For Arteriovenous Fistulas and Grafts:
  /// - Verifies presence of thrill (palpable vibration) and bruit (audible murmur).
  ///
  /// For Dialysis Central Lines (Permcath/CVC):
  /// - Inspects for signs of exit-site infection (redness, swelling, discharge, pain).
  static List<String> getAccessSafetyWarnings({
    required String accessType,
    bool? thrillPresent,
    bool? bruitPresent,
    bool? rednessPresent,
    bool? swellingPresent,
    bool? dischargePresent,
    bool? painPresent,
  }) {
    final warnings = <String>[];
    final parsed = VascularAccessType.fromString(accessType);
    final isFistulaOrGraft = parsed?.isFistulaOrGraft ?? false;
    final isCentralLine = parsed?.isCentralLine ?? false;

    if (isFistulaOrGraft) {
      if (thrillPresent == false) {
        warnings.add('Absent thrill detected in vascular fistula/graft.');
      }
      if (bruitPresent == false) {
        warnings.add('Absent bruit detected in vascular fistula/graft.');
      }
    }

    if (isCentralLine) {
      if (rednessPresent == true) {
        warnings.add('Exit-site redness detected.');
      }
      if (swellingPresent == true) {
        warnings.add('Exit-site swelling detected.');
      }
      if (dischargePresent == true) {
        warnings.add('Exit-site discharge detected.');
      }
      if (painPresent == true) {
        warnings.add('Exit-site pain reported.');
      }
    }

    return warnings;
  }
}

/// Lifecycle states of a unified hemodialysis session per Issue #15.
enum DialysisSessionStatus {
  inProgress('inProgress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const DialysisSessionStatus(this.value, this.displayName);

  static DialysisSessionStatus fromString(String? val) {
    if (val == null) return DialysisSessionStatus.completed;
    for (final status in DialysisSessionStatus.values) {
      if (status.value.toLowerCase() == val.toLowerCase() ||
          status.name.toLowerCase() == val.toLowerCase()) {
        return status;
      }
    }
    return DialysisSessionStatus.completed;
  }
}

