import 'package:flutter/material.dart';

/// Clinical alert status for indwelling Urine Foley Catheter 14-day lifespan.
enum CatheterLifespanStatus {
  /// Days 1–10: Normal operational lifespan window.
  green,

  /// Days 11–14: Approaching 14-day lifespan limit. Catheter replacement mandated soon.
  amber,

  /// Days 15+: Catheter-Associated Urinary Tract Infection (CAUTI) Risk Window active.
  /// Immediate catheter replacement clinically required.
  red,
}

/// Standardized 4-tier Hematuria Grade information per CONTEXT.md.
class HematuriaGradeInfo {
  final int grade;
  final String title;
  final String description;
  final Color color;

  const HematuriaGradeInfo({
    required this.grade,
    required this.title,
    required this.description,
    required this.color,
  });

  static const Map<int, HematuriaGradeInfo> grades = {
    1: HematuriaGradeInfo(
      grade: 1,
      title: 'Grade 1: Clear/Yellow',
      description: 'Clear, yellow, or light straw-colored urine without visible blood',
      color: Color(0xFFFDD835),
    ),
    2: HematuriaGradeInfo(
      grade: 2,
      title: 'Grade 2: Light Pink/Microscopic',
      description: 'Light pink or microscopic bleeding, rose or tea tint',
      color: Color(0xFFF48FB1),
    ),
    3: HematuriaGradeInfo(
      grade: 3,
      title: 'Grade 3: Red/Gross',
      description: 'Frank red blood, gross hematuria without significant clotting',
      color: Color(0xFFE53935),
    ),
    4: HematuriaGradeInfo(
      grade: 4,
      title: 'Grade 4: Dark Burgundy/Clots',
      description: 'Dark burgundy or frank blood with active clots, catheter obstruction risk',
      color: Color(0xFF880E4F),
    ),
  };

  static HematuriaGradeInfo fromGrade(int grade) {
    final info = grades[grade];
    if (info == null) {
      throw ArgumentError('Invalid Hematuria Grade: $grade. Expected 1, 2, 3, or 4 per CONTEXT.md.');
    }
    return info;
  }
}

/// Evaluation summary of the Urine Foley Catheter 14-day lifespan cycle.
class CatheterLifespanSummary {
  final DateTime insertionDate;
  final DateTime replacementDueDate;
  final DateTime asOf;
  final int dayOfCycle;
  final int daysElapsed;
  final int daysRemaining;
  final int daysOverdue;
  final CatheterLifespanStatus status;
  final bool isCautiRiskActive;

  const CatheterLifespanSummary({
    required this.insertionDate,
    required this.replacementDueDate,
    required this.asOf,
    required this.dayOfCycle,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.daysOverdue,
    required this.status,
    required this.isCautiRiskActive,
  });

  String get statusTitle {
    switch (status) {
      case CatheterLifespanStatus.green:
        return 'Lifespan Optimal (Days 1–10)';
      case CatheterLifespanStatus.amber:
        return 'Replacement Approaching (Days 11–14)';
      case CatheterLifespanStatus.red:
        return 'CAUTI Risk Window Active (Days 15+)';
    }
  }

  String get statusDescription {
    switch (status) {
      case CatheterLifespanStatus.green:
        return 'Foley catheter is within the normal 14-day lifespan cycle. Continue monitoring drainage and hematuria.';
      case CatheterLifespanStatus.amber:
        return 'Catheter has reached day $dayOfCycle of 14. Plan clinical replacement within $daysRemaining day${daysRemaining == 1 ? '' : 's'}.';
      case CatheterLifespanStatus.red:
        return 'Catheter has exceeded 14 days of indwelling placement ($daysOverdue day${daysOverdue == 1 ? '' : 's'} past due). Immediate replacement required to avoid CAUTI.';
    }
  }

  Color get statusColor {
    switch (status) {
      case CatheterLifespanStatus.green:
        return const Color(0xFF2E7D32); // Green
      case CatheterLifespanStatus.amber:
        return const Color(0xFFEF6C00); // Amber / Orange
      case CatheterLifespanStatus.red:
        return const Color(0xFFC62828); // Red
    }
  }

  Color get statusBackgroundColor {
    switch (status) {
      case CatheterLifespanStatus.green:
        return const Color(0xFFE8F5E9);
      case CatheterLifespanStatus.amber:
        return const Color(0xFFFFF3E0);
      case CatheterLifespanStatus.red:
        return const Color(0xFFFFEBEE);
    }
  }
}

/// Clinical calculation rules for indwelling Urine Foley Catheter 14-day lifespan cycle per CONTEXT.md.
class CatheterLifespanRules {
  /// Standard clinical lifespan of indwelling Foley Catheter before replacement.
  static const int lifespanDays = 14;

  /// Evaluates the 14-day lifespan cycle and CAUTI risk window for a catheter.
  ///
  /// Transitions:
  /// - Green: Days 1–10 (normal cycle)
  /// - Amber: Days 11–14 (timely replacement mandated)
  /// - Red: Days 15+ (CAUTI Risk Window active)
  static CatheterLifespanSummary evaluateLifespan({
    required DateTime insertionDate,
    DateTime? asOf,
    DateTime? replacementDueDate,
  }) {
    final referenceTime = asOf?.toUtc() ?? DateTime.now().toUtc();
    final insertUtc = insertionDate.toUtc();
    final dueDate = replacementDueDate?.toUtc() ?? insertUtc.add(const Duration(days: lifespanDays));

    // Calculate calendar days difference or full 24-hour periods
    // Difference from insertion date:
    final difference = referenceTime.difference(insertUtc);
    final daysElapsed = difference.inDays < 0 ? 0 : difference.inDays;
    final dayOfCycle = daysElapsed + 1;

    CatheterLifespanStatus status;
    bool isCautiRiskActive = false;
    int daysRemaining = 0;
    int daysOverdue = 0;

    if (dayOfCycle <= 10) {
      status = CatheterLifespanStatus.green;
      daysRemaining = (lifespanDays - daysElapsed).clamp(0, lifespanDays);
    } else if (dayOfCycle <= 14) {
      status = CatheterLifespanStatus.amber;
      daysRemaining = (lifespanDays - daysElapsed).clamp(0, lifespanDays);
    } else {
      // Days 15+ -> CAUTI Risk Window active
      status = CatheterLifespanStatus.red;
      isCautiRiskActive = true;
      daysRemaining = 0;
      daysOverdue = dayOfCycle - lifespanDays; // Day 15 is 1 day past due, Day 16 is 2 days past due
    }

    return CatheterLifespanSummary(
      insertionDate: insertUtc,
      replacementDueDate: dueDate,
      asOf: referenceTime,
      dayOfCycle: dayOfCycle,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      daysOverdue: daysOverdue,
      status: status,
      isCautiRiskActive: isCautiRiskActive,
    );
  }
}
