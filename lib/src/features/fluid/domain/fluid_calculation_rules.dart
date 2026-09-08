import 'dart:math' as math;
import 'fluid_balance_summary.dart';

/// Clinical domain calculation and safety rules for 24-hour Fluid Balance,
/// Fluid Allowance progression, and Phosphate Binder administration timing.
class FluidCalculationRules {
  /// Educational contextual prompt defined in CONTEXT.md for Phosphate Binder administration.
  static const String phosphateBinderEducationalPrompt =
      'Phosphate Binders must be ingested strictly during or immediately following meals and fluids to sequester dietary phosphorus.';

  /// Standard clinical rapid volume presets in milliliters.
  static const List<int> defaultVolumePresetsMl = [100, 150, 200, 250, 500];

  /// Computes the net 24-hour Fluid Balance in milliliters.
  ///
  /// Per CONTEXT.md: "The net difference between total fluid consumed and total fluid
  /// evacuated (urine output and ultrafiltration) over a 24-hour period."
  static int calculateNetBalance({
    required int totalIntakeMl,
    required int totalOutputMl,
  }) {
    return totalIntakeMl - totalOutputMl;
  }

  /// Calculates remaining fluid volume permitted today before hitting the allowance.
  /// Returns 0 if cumulative intake matches or exceeds the prescribed allowance.
  static int calculateRemainingAllowance({
    required int cumulativeIntakeMl,
    required int dailyFluidAllowanceMl,
  }) {
    return math.max(0, dailyFluidAllowanceMl - cumulativeIntakeMl);
  }

  /// Calculates cumulative intake as a percentage of prescribed allowance.
  static double calculateAllowancePercentage({
    required int cumulativeIntakeMl,
    required int dailyFluidAllowanceMl,
  }) {
    if (dailyFluidAllowanceMl <= 0) return 0.0;
    final percentage = (cumulativeIntakeMl / dailyFluidAllowanceMl) * 100.0;
    // Round to 1 decimal place
    return double.parse(percentage.toStringAsFixed(1));
  }

  /// Categorizes visual progression adherence status against prescribed daily allowance.
  static FluidAllowanceStatus calculateAllowanceStatus({
    required int cumulativeIntakeMl,
    int? dailyFluidAllowanceMl,
  }) {
    if (dailyFluidAllowanceMl == null || dailyFluidAllowanceMl <= 0) {
      return FluidAllowanceStatus.noAllowanceSpecified;
    }

    final ratio = cumulativeIntakeMl / dailyFluidAllowanceMl;
    if (ratio > 1.0) {
      return FluidAllowanceStatus.exceeded;
    } else if (ratio >= 0.85) {
      return FluidAllowanceStatus.nearingLimit;
    } else {
      return FluidAllowanceStatus.withinLimit;
    }
  }

  /// Aggregates 24-hour fluid metrics into a unified [FluidBalanceSummary].
  static FluidBalanceSummary buildSummary({
    required int totalIntakeMl,
    required int totalOutputMl,
    int? dailyFluidAllowanceMl,
  }) {
    final netBalance = calculateNetBalance(
      totalIntakeMl: totalIntakeMl,
      totalOutputMl: totalOutputMl,
    );

    double? percentage;
    int? remaining;
    FluidAllowanceStatus status = FluidAllowanceStatus.noAllowanceSpecified;

    if (dailyFluidAllowanceMl != null && dailyFluidAllowanceMl > 0) {
      percentage = calculateAllowancePercentage(
        cumulativeIntakeMl: totalIntakeMl,
        dailyFluidAllowanceMl: dailyFluidAllowanceMl,
      );
      remaining = calculateRemainingAllowance(
        cumulativeIntakeMl: totalIntakeMl,
        dailyFluidAllowanceMl: dailyFluidAllowanceMl,
      );
      status = calculateAllowanceStatus(
        cumulativeIntakeMl: totalIntakeMl,
        dailyFluidAllowanceMl: dailyFluidAllowanceMl,
      );
    }

    return FluidBalanceSummary(
      totalIntakeMl: totalIntakeMl,
      totalOutputMl: totalOutputMl,
      netBalanceMl: netBalance,
      dailyFluidAllowanceMl: dailyFluidAllowanceMl,
      intakePercentageOfAllowance: percentage,
      remainingAllowanceMl: remaining,
      allowanceStatus: status,
    );
  }
}
