import '../../../core/database/app_database.dart';
import '../../profile/domain/clinical_condition.dart';

/// Exception thrown when an action violates the Fistula Arm Safety Flag per ADR-0003.
class FistulaArmSafetyException implements Exception {
  final String message;

  const FistulaArmSafetyException(this.message);

  @override
  String toString() => 'FistulaArmSafetyException: $message';
}

/// Evaluates vascular access safety rules and arm lockouts per ADR-0003.
class VascularSafetyRules {
  /// Checks whether the patient has an active vascular access located on an arm.
  static bool hasArmAccess(Patient patient) {
    final accessType = VascularAccessType.fromString(patient.vascularAccessType);
    if (accessType == VascularAccessType.none) {
      return false;
    }

    final location = AccessLocation.fromString(patient.fistulaArmLocation);
    if (location == null || !location.isArm) {
      return false;
    }

    return true;
  }

  /// Returns the arm location string ('leftArm' or 'rightArm') prohibited from blood pressure measurement,
  /// or `null` if no arm is prohibited.
  static String? getProhibitedArm(Patient patient) {
    if (!hasArmAccess(patient)) {
      return null;
    }
    return patient.fistulaArmLocation;
  }

  /// Returns the designated safe arm ('leftArm' or 'rightArm') for blood pressure measurement,
  /// or `null` if both arms are safe.
  static String? getSafeArm(Patient patient) {
    final prohibited = getProhibitedArm(patient);
    if (prohibited == 'leftArm') {
      return 'rightArm';
    } else if (prohibited == 'rightArm') {
      return 'leftArm';
    }
    return null;
  }

  /// Determines if a specific arm ('leftArm' or 'rightArm') is safe for blood pressure cuff placement.
  static bool isArmSafe({
    required Patient patient,
    required String arm,
  }) {
    final prohibited = getProhibitedArm(patient);
    if (prohibited == null) {
      return true;
    }
    return arm != prohibited;
  }
}

/// Extension on [Patient] providing idiomatic access to vascular safety rules.
extension PatientVascularSafety on Patient {
  /// Whether the patient has an active vascular access on an arm.
  bool get hasArmAccess => VascularSafetyRules.hasArmAccess(this);

  /// The arm location prohibited from blood pressure measurement, or null if neither arm is prohibited.
  String? get prohibitedArm => VascularSafetyRules.getProhibitedArm(this);

  /// The designated safe arm for blood pressure measurement, or null if both arms are safe.
  String? get safeArm => VascularSafetyRules.getSafeArm(this);

  /// Checks whether a specific arm is safe for measurement.
  bool isArmSafe(String arm) => VascularSafetyRules.isArmSafe(patient: this, arm: arm);
}
