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

  /// Total native residual urine evacuated in milliliters.
  final int totalUrineOutputMl;

  /// Machine ultrafiltration extracted from completed dialysis sessions in milliliters.
  final int machineUltrafiltrationMl;

  /// Total fluid volume evacuated (urine + ultrafiltration) in milliliters.
  final int totalOutputMl;

  /// Native Urine Balance: Total Fluid Intake (24h) - Total Urine Output (24h).
  ///
  /// Represents natural renal fluid retention before dialysis.
  final int nativeUrineBalanceMl;

  /// Dialytic Fluid Balance: Total Fluid Intake (24h) - (Total Urine Output (24h) + Machine Ultrafiltration (24h)).
  ///
  /// Represents comprehensive 24-hour hydration and volume status.
  final int dialyticFluidBalanceMl;

  /// Net 24-hour fluid balance in milliliters (identical to [dialyticFluidBalanceMl]).
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
    int? totalUrineOutputMl,
    int? machineUltrafiltrationMl,
    int? totalOutputMl,
    int? nativeUrineBalanceMl,
    int? dialyticFluidBalanceMl,
    int? netBalanceMl,
    this.dailyFluidAllowanceMl,
    this.intakePercentageOfAllowance,
    this.remainingAllowanceMl,
    this.allowanceStatus = FluidAllowanceStatus.withinLimit,
  })  : totalUrineOutputMl = totalUrineOutputMl ?? (totalOutputMl ?? 0),
        machineUltrafiltrationMl = machineUltrafiltrationMl ?? 0,
        totalOutputMl = totalOutputMl ?? ((totalUrineOutputMl ?? 0) + (machineUltrafiltrationMl ?? 0)),
        nativeUrineBalanceMl = nativeUrineBalanceMl ?? (totalIntakeMl - (totalUrineOutputMl ?? (totalOutputMl ?? 0))),
        dialyticFluidBalanceMl = dialyticFluidBalanceMl ?? (netBalanceMl ?? (totalIntakeMl - (totalOutputMl ?? (totalUrineOutputMl ?? 0) + (machineUltrafiltrationMl ?? 0)))),
        netBalanceMl = netBalanceMl ?? (dialyticFluidBalanceMl ?? (totalIntakeMl - (totalOutputMl ?? (totalUrineOutputMl ?? 0) + (machineUltrafiltrationMl ?? 0))));

  /// Utility to format volume with comma thousands separator.
  static String formatVolume(int volumeMl) {
    final isNegative = volumeMl < 0;
    final absStr = volumeMl.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < absStr.length; i++) {
      if (i > 0 && (absStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absStr[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()}';
  }

  /// Formatted body fluid retention text (e.g., "+350 mL" or "-200 mL").
  String get bodyFluidRetentionText {
    final retentionSign = nativeUrineBalanceMl >= 0 ? '+' : '-';
    return '$retentionSign${formatVolume(nativeUrineBalanceMl.abs())} mL';
  }

  /// Formatted dialysis extraction text (e.g., "-2,000 mL" or "0 mL").
  String get dialysisRemovalText {
    return machineUltrafiltrationMl > 0
        ? '-${formatVolume(machineUltrafiltrationMl)} mL'
        : '0 mL';
  }

  /// Formatted net dialytic fluid balance text (e.g., "-1,650 mL" or "+350 mL").
  String get netBalanceText {
    final netSign = dialyticFluidBalanceMl >= 0 ? '+' : '-';
    return '$netSign${formatVolume(dialyticFluidBalanceMl.abs())} mL';
  }

  /// Plain-language clinical summary displaying Body Fluid Retention, Dialysis Removal,
  /// and Net Balance to prevent confusing elderly patients and attendants per Issue #17.
  String get plainLanguageSummary {
    return 'Body Fluid Retention: $bodyFluidRetentionText | Dialysis Removal: $dialysisRemovalText | Net Balance: $netBalanceText';
  }

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
