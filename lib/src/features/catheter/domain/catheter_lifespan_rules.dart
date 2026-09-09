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

/// Indwelling Foley catheter material and standard clinical lifespan options.
enum CatheterMaterial {
  latex14Day(
    displayName: '14-Day Latex',
    materialName: 'Latex',
    defaultLifespanDays: 14,
    amberWindowDays: 4,
  ),
  silicone30Day(
    displayName: '30-Day Silicone',
    materialName: 'Silicone (Short-term)',
    defaultLifespanDays: 30,
    amberWindowDays: 7,
  ),
  silicone90Day(
    displayName: '90-Day Silicone',
    materialName: 'Silicone (Long-term)',
    defaultLifespanDays: 90,
    amberWindowDays: 14,
  ),
  custom(
    displayName: 'Custom Duration',
    materialName: 'Custom Material',
    defaultLifespanDays: 14,
    amberWindowDays: 4,
  );

  final String displayName;
  final String materialName;
  final int defaultLifespanDays;
  final int amberWindowDays;

  const CatheterMaterial({
    required this.displayName,
    required this.materialName,
    required this.defaultLifespanDays,
    required this.amberWindowDays,
  });

  static CatheterMaterial fromString(String? name) {
    if (name == null) return CatheterMaterial.latex14Day;
    for (final mat in CatheterMaterial.values) {
      if (mat.name == name) return mat;
    }
    return CatheterMaterial.latex14Day;
  }
}

/// Evaluation summary of the indwelling Urine Foley Catheter lifespan cycle.
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
  final CatheterMaterial material;
  final int totalLifespanDays;
  final int? bagEmptyingIntervalHours;
  final DateTime? lastBagEmptiedAt;
  final DateTime? nextBagEmptyingDue;
  final bool isBagEmptyingDue;
  final int? minutesUntilNextBagEmptying;

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
    this.material = CatheterMaterial.latex14Day,
    this.totalLifespanDays = 14,
    this.effectiveAmberWindowDays = 4,
    this.bagEmptyingIntervalHours,
    this.lastBagEmptiedAt,
    this.nextBagEmptyingDue,
    this.isBagEmptyingDue = false,
    this.minutesUntilNextBagEmptying,
  });

  final int effectiveAmberWindowDays;

  String get statusTitle {
    final amberStart = totalLifespanDays - effectiveAmberWindowDays + 1;
    final greenEnd = amberStart - 1;
    switch (status) {
      case CatheterLifespanStatus.green:
        return 'Lifespan Optimal (Days 1–$greenEnd)';
      case CatheterLifespanStatus.amber:
        return 'Replacement Approaching (Days $amberStart–$totalLifespanDays)';
      case CatheterLifespanStatus.red:
        return 'CAUTI Risk Window Active (Days ${totalLifespanDays + 1}+)';
    }
  }

  String get statusDescription {
    switch (status) {
      case CatheterLifespanStatus.green:
        return 'Foley catheter is within the normal $totalLifespanDays-day lifespan cycle. Continue monitoring drainage and hematuria.';
      case CatheterLifespanStatus.amber:
        return 'Catheter has reached day $dayOfCycle of $totalLifespanDays. Plan clinical replacement within $daysRemaining day${daysRemaining == 1 ? '' : 's'}.';
      case CatheterLifespanStatus.red:
        return 'Catheter has exceeded $totalLifespanDays days of indwelling placement ($daysOverdue day${daysOverdue == 1 ? '' : 's'} past due). Immediate replacement required to avoid CAUTI.';
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

/// Clinical calculation rules for indwelling Urine Foley Catheter lifespan cycle per CONTEXT.md.
class CatheterLifespanRules {
  /// Standard clinical lifespan of indwelling Foley Catheter before replacement.
  static const int lifespanDays = 14;

  /// Evaluates the lifespan cycle, dynamic CAUTI risk window, and collection bag emptying schedule.
  static CatheterLifespanSummary evaluateLifespan({
    required DateTime insertionDate,
    DateTime? asOf,
    DateTime? replacementDueDate,
    CatheterMaterial material = CatheterMaterial.latex14Day,
    int? customLifespanDays,
    int? bagEmptyingIntervalHours,
    DateTime? lastBagEmptiedAt,
  }) {
    final referenceTime = asOf?.toUtc() ?? DateTime.now().toUtc();
    final insertUtc = insertionDate.toUtc();

    // Determine totalLifespanDays
    int totalLifespan;
    if (customLifespanDays != null && customLifespanDays > 0) {
      totalLifespan = customLifespanDays;
    } else if (replacementDueDate != null) {
      final diff = replacementDueDate.toUtc().difference(insertUtc).inDays;
      totalLifespan = diff > 0 ? diff : material.defaultLifespanDays;
    } else {
      totalLifespan = material.defaultLifespanDays;
    }

    final dueDate = replacementDueDate?.toUtc() ?? insertUtc.add(Duration(days: totalLifespan));

    final difference = referenceTime.difference(insertUtc);
    final daysElapsed = difference.inDays < 0 ? 0 : difference.inDays;
    final dayOfCycle = daysElapsed + 1;

    final effectiveAmberWindow = material == CatheterMaterial.custom
        ? (totalLifespan * 0.2).round().clamp(3, 14)
        : material.amberWindowDays;
    final amberStartDay = totalLifespan - effectiveAmberWindow + 1;

    CatheterLifespanStatus status;
    bool isCautiRiskActive = false;
    int daysRemaining = 0;
    int daysOverdue = 0;

    if (dayOfCycle < amberStartDay) {
      status = CatheterLifespanStatus.green;
      daysRemaining = (totalLifespan - daysElapsed).clamp(0, totalLifespan);
    } else if (dayOfCycle <= totalLifespan) {
      status = CatheterLifespanStatus.amber;
      daysRemaining = (totalLifespan - daysElapsed).clamp(0, totalLifespan);
    } else {
      status = CatheterLifespanStatus.red;
      isCautiRiskActive = true;
      daysRemaining = 0;
      daysOverdue = dayOfCycle - totalLifespan;
    }

    // Collection bag emptying interval calculations
    DateTime? nextBagEmptyingDue;
    bool isBagEmptyingDue = false;
    int? minutesUntilNextBagEmptying;

    if (bagEmptyingIntervalHours != null && bagEmptyingIntervalHours > 0) {
      final baselineTime = (lastBagEmptiedAt != null) ? lastBagEmptiedAt.toUtc() : insertUtc;
      nextBagEmptyingDue = baselineTime.add(Duration(hours: bagEmptyingIntervalHours));
      final diffMinutes = nextBagEmptyingDue.difference(referenceTime).inMinutes;
      if (diffMinutes <= 0) {
        isBagEmptyingDue = true;
        minutesUntilNextBagEmptying = 0;
      } else {
        isBagEmptyingDue = false;
        minutesUntilNextBagEmptying = diffMinutes;
      }
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
      material: material,
      totalLifespanDays: totalLifespan,
      effectiveAmberWindowDays: effectiveAmberWindow,
      bagEmptyingIntervalHours: bagEmptyingIntervalHours,
      lastBagEmptiedAt: lastBagEmptiedAt?.toUtc(),
      nextBagEmptyingDue: nextBagEmptyingDue,
      isBagEmptyingDue: isBagEmptyingDue,
      minutesUntilNextBagEmptying: minutesUntilNextBagEmptying,
    );
  }
}
