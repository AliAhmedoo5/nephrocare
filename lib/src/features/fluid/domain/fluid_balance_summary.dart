/// Tiers of fluid allowance adherence for visual progression styling.
enum FluidAllowanceStatus {
  /// Intake is well below the prescribed daily allowance (< 85%).
  withinLimit,

  /// Intake is approaching the prescribed daily allowance (85% - 100%).
  nearingLimit,

  /// Intake has exceeded the prescribed daily allowance (> 100%).
  exceeded,

  /// No prescribed daily allowance has been assigned in the patient profile.
  noAllowanceSpecified,
}

/// Immutable clinical summary of 24-hour fluid dynamics.
class FluidBalanceSummary {
  /// Total fluid volume consumed within the 24-hour cycle in milliliters.
  final int totalIntakeMl;

  /// Total fluid volume evacuated (urine, peritoneal dialysate, ultrafiltration) in milliliters.
  final int totalOutputMl;

  /// Net 24-hour fluid balance in milliliters (totalIntakeMl - totalOutputMl).
  final int netBalanceMl;

  /// The patient's nephrologist-assigned 24-hour Fluid Allowance in milliliters, if prescribed.
  final int? dailyFluidAllowanceMl;

  /// Cumulative intake expressed as a percentage of the prescribed allowance.
  final double? intakePercentageOfAllowance;

  /// Remaining volume permitted before reaching prescribed allowance (0 if exceeded).
  final int? remainingAllowanceMl;

  /// Clinical status indicating adherence level against the prescribed allowance.
  final FluidAllowanceStatus allowanceStatus;

  const FluidBalanceSummary({
    required this.totalIntakeMl,
    required this.totalOutputMl,
    required this.netBalanceMl,
    this.dailyFluidAllowanceMl,
    this.intakePercentageOfAllowance,
    this.remainingAllowanceMl,
    this.allowanceStatus = FluidAllowanceStatus.withinLimit,
  });

  /// Formatted representation of cumulative intake against allowance.
  String get formattedIntakeProgression {
    final allowance = dailyFluidAllowanceMl;
    if (allowance != null && allowance > 0) {
      return '$totalIntakeMl / $allowance mL (${intakePercentageOfAllowance ?? 0}%)';
    }
    return '$totalIntakeMl mL logged';
  }

  /// Formatted representation of output volume with net balance.
  String get formattedOutputWithNet {
    final sign = netBalanceMl >= 0 ? '+' : '';
    return 'Output: $totalOutputMl mL | Net: $sign$netBalanceMl mL';
  }

  /// Formatted 24-hour net balance.
  String get formattedNetBalance24h {
    final sign = netBalanceMl >= 0 ? '+' : '';
    return 'Net: $sign$netBalanceMl mL (24h)';
  }
}
