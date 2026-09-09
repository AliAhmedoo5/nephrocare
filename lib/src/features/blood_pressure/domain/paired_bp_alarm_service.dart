import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a scheduled local background alarm for a follow-up blood pressure measurement.
class ScheduledPairedAlarm {
  final String pairedAssessmentId;
  final String patientId;
  final String medicationAdministrationId;
  final String medicationName;
  final DateTime scheduledFor;
  final int intervalMinutes;
  final int baselineSystolic;
  final int baselineDiastolic;
  final int baselinePulse;
  final String safeArm;
  final bool isTriggered;

  const ScheduledPairedAlarm({
    required this.pairedAssessmentId,
    required this.patientId,
    required this.medicationAdministrationId,
    required this.medicationName,
    required this.scheduledFor,
    required this.intervalMinutes,
    required this.baselineSystolic,
    required this.baselineDiastolic,
    required this.baselinePulse,
    required this.safeArm,
    this.isTriggered = false,
  });

  ScheduledPairedAlarm copyWith({
    bool? isTriggered,
  }) {
    return ScheduledPairedAlarm(
      pairedAssessmentId: pairedAssessmentId,
      patientId: patientId,
      medicationAdministrationId: medicationAdministrationId,
      medicationName: medicationName,
      scheduledFor: scheduledFor,
      intervalMinutes: intervalMinutes,
      baselineSystolic: baselineSystolic,
      baselineDiastolic: baselineDiastolic,
      baselinePulse: baselinePulse,
      safeArm: safeArm,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }
}

/// Service managing scheduled local background alarms for the pharmacological onset window (20–35 min).
///
/// Ensures anti-hypertensive hemodynamic follow-up prompts trigger on time even if the app
/// was closed or the device was locked, per ADR-0005.
class PairedBpAlarmService {
  final Map<String, ScheduledPairedAlarm> _alarms = {};
  final Map<String, Timer> _timers = {};
  final StreamController<ScheduledPairedAlarm> _triggerController =
      StreamController<ScheduledPairedAlarm>.broadcast();
  final bool enableTimers;

  PairedBpAlarmService({this.enableTimers = false});

  Stream<ScheduledPairedAlarm> get onAlarmTriggered => _triggerController.stream;

  /// Schedules an alarm for the follow-up measurement.
  Future<void> scheduleAlarm({
    required String pairedAssessmentId,
    required String patientId,
    required String medicationAdministrationId,
    required String medicationName,
    required DateTime scheduledFor,
    required int intervalMinutes,
    required int baselineSystolic,
    required int baselineDiastolic,
    required int baselinePulse,
    required String safeArm,
  }) async {
    final alarm = ScheduledPairedAlarm(
      pairedAssessmentId: pairedAssessmentId,
      patientId: patientId,
      medicationAdministrationId: medicationAdministrationId,
      medicationName: medicationName,
      scheduledFor: scheduledFor,
      intervalMinutes: intervalMinutes,
      baselineSystolic: baselineSystolic,
      baselineDiastolic: baselineDiastolic,
      baselinePulse: baselinePulse,
      safeArm: safeArm,
    );
    _alarms[pairedAssessmentId] = alarm;

    _timers[pairedAssessmentId]?.cancel();
    if (enableTimers) {
      final remaining = scheduledFor.difference(DateTime.now().toUtc());
      if (remaining.isNegative) {
        triggerAlarm(pairedAssessmentId);
      } else {
        _timers[pairedAssessmentId] = Timer(remaining, () {
          triggerAlarm(pairedAssessmentId);
        });
      }
    }
  }

  /// Cancels or clears a scheduled alarm when completed or dismissed.
  Future<void> cancelAlarm(String pairedAssessmentId) async {
    _timers[pairedAssessmentId]?.cancel();
    _timers.remove(pairedAssessmentId);
    _alarms.remove(pairedAssessmentId);
  }

  /// Retrieves a scheduled alarm for a given assessment ID.
  ScheduledPairedAlarm? getAlarmForAssessment(String pairedAssessmentId) {
    return _alarms[pairedAssessmentId];
  }

  /// Retrieves all active scheduled alarms, optionally filtered by patient ID.
  List<ScheduledPairedAlarm> getActiveAlarms({String? patientId}) {
    if (patientId != null) {
      return _alarms.values.where((a) => a.patientId == patientId).toList();
    }
    return _alarms.values.toList();
  }

  /// Checks all active alarms against the current time and triggers any that are due.
  /// Used on app launch or resume.
  void checkDueAlarms() {
    final now = DateTime.now().toUtc();
    for (final alarm in _alarms.values) {
      if (!alarm.isTriggered && (now.isAfter(alarm.scheduledFor) || now.isAtSameMomentAs(alarm.scheduledFor))) {
        triggerAlarm(alarm.pairedAssessmentId);
      }
    }
  }

  /// Triggers the alarm (timer-based or on app reopening when scheduled time has arrived).
  void triggerAlarm(String pairedAssessmentId) {
    final alarm = _alarms[pairedAssessmentId];
    if (alarm != null && !alarm.isTriggered) {
      final updated = alarm.copyWith(isTriggered: true);
      _alarms[pairedAssessmentId] = updated;
      _triggerController.add(updated);
    }
  }

  /// Disposes resources.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _triggerController.close();
  }
}

/// Provider for [PairedBpAlarmService].
final pairedBpAlarmServiceProvider = Provider<PairedBpAlarmService>((ref) {
  final service = PairedBpAlarmService();
  ref.onDispose(() => service.dispose());
  return service;
});
