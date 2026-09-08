import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/fluid/domain/fluid_calculation_rules.dart';
import 'package:nephrocare/src/features/fluid/domain/fluid_balance_summary.dart';

void main() {
  group('Unified Application & State Seam: Fluid Domain Calculation Rules', () {
    test('calculateNetBalance computes exact net difference between intake and output over 24-hour cycle', () {
      // Net Fluid Balance = Total Consumed - Total Evacuated per CONTEXT.md
      expect(FluidCalculationRules.calculateNetBalance(totalIntakeMl: 1200, totalOutputMl: 800), equals(400));
      expect(FluidCalculationRules.calculateNetBalance(totalIntakeMl: 600, totalOutputMl: 1000), equals(-400));
      expect(FluidCalculationRules.calculateNetBalance(totalIntakeMl: 1500, totalOutputMl: 1500), equals(0));
    });

    test('calculateRemainingAllowance calculates remaining volume or 0 when exceeded', () {
      expect(
        FluidCalculationRules.calculateRemainingAllowance(cumulativeIntakeMl: 800, dailyFluidAllowanceMl: 1500),
        equals(700),
      );
      expect(
        FluidCalculationRules.calculateRemainingAllowance(cumulativeIntakeMl: 1500, dailyFluidAllowanceMl: 1500),
        equals(0),
      );
      expect(
        FluidCalculationRules.calculateRemainingAllowance(cumulativeIntakeMl: 1750, dailyFluidAllowanceMl: 1500),
        equals(0),
      );
    });

    test('calculateAllowancePercentage computes precise percentage against prescribed Fluid Allowance', () {
      expect(
        FluidCalculationRules.calculateAllowancePercentage(cumulativeIntakeMl: 750, dailyFluidAllowanceMl: 1500),
        equals(50.0),
      );
      expect(
        FluidCalculationRules.calculateAllowancePercentage(cumulativeIntakeMl: 1500, dailyFluidAllowanceMl: 1500),
        equals(100.0),
      );
      expect(
        FluidCalculationRules.calculateAllowancePercentage(cumulativeIntakeMl: 1800, dailyFluidAllowanceMl: 1500),
        equals(120.0),
      );
    });

    test('calculateAllowanceStatus categorizes visual progression tiers accurately', () {
      // Normal: < 85%
      expect(
        FluidCalculationRules.calculateAllowanceStatus(cumulativeIntakeMl: 1000, dailyFluidAllowanceMl: 1500),
        equals(FluidAllowanceStatus.withinLimit),
      );

      // Nearing Limit: 85% - 100%
      expect(
        FluidCalculationRules.calculateAllowanceStatus(cumulativeIntakeMl: 1300, dailyFluidAllowanceMl: 1500),
        equals(FluidAllowanceStatus.nearingLimit),
      );
      expect(
        FluidCalculationRules.calculateAllowanceStatus(cumulativeIntakeMl: 1500, dailyFluidAllowanceMl: 1500),
        equals(FluidAllowanceStatus.nearingLimit),
      );

      // Exceeded: > 100%
      expect(
        FluidCalculationRules.calculateAllowanceStatus(cumulativeIntakeMl: 1501, dailyFluidAllowanceMl: 1500),
        equals(FluidAllowanceStatus.exceeded),
      );

      // Null allowance: noAllowanceSpecified
      expect(
        FluidCalculationRules.calculateAllowanceStatus(cumulativeIntakeMl: 500, dailyFluidAllowanceMl: null),
        equals(FluidAllowanceStatus.noAllowanceSpecified),
      );
    });

    test('buildSummary aggregates all 24-hour fluid metrics into immutable FluidBalanceSummary', () {
      final summary = FluidCalculationRules.buildSummary(
        totalIntakeMl: 1200,
        totalOutputMl: 900,
        dailyFluidAllowanceMl: 1500,
      );

      expect(summary.totalIntakeMl, equals(1200));
      expect(summary.totalOutputMl, equals(900));
      expect(summary.netBalanceMl, equals(300));
      expect(summary.dailyFluidAllowanceMl, equals(1500));
      expect(summary.intakePercentageOfAllowance, equals(80.0));
      expect(summary.remainingAllowanceMl, equals(300));
      expect(summary.allowanceStatus, equals(FluidAllowanceStatus.withinLimit));
    });

    test('Phosphate Binder guidance text conforms strictly to CONTEXT.md therapeutic language', () {
      expect(
        FluidCalculationRules.phosphateBinderEducationalPrompt,
        contains('Phosphate Binders must be ingested strictly during or immediately following meals and fluids to sequester dietary phosphorus.'),
      );
    });
  });
}
