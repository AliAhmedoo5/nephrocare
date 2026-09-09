import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/catheter/domain/catheter_lifespan_rules.dart';

void main() {
  group('CatheterLifespanRules & 14-Day Countdown Engine', () {
    final insertionDate = DateTime.utc(2026, 9, 1, 8, 0);

    test('Transitions correctly through Green state for days 1 to 10', () {
      // Day 1 (immediate insertion)
      final day1 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 1, 12, 0),
      );
      expect(day1.dayOfCycle, equals(1));
      expect(day1.daysElapsed, equals(0));
      expect(day1.status, equals(CatheterLifespanStatus.green));
      expect(day1.isCautiRiskActive, isFalse);
      expect(day1.daysRemaining, equals(14));

      // Day 5
      final day5 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 5, 8, 0),
      );
      expect(day5.dayOfCycle, equals(5));
      expect(day5.daysElapsed, equals(4));
      expect(day5.status, equals(CatheterLifespanStatus.green));
      expect(day5.isCautiRiskActive, isFalse);
      expect(day5.daysRemaining, equals(10));

      // Day 10 (end of green window)
      final day10 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 10, 23, 59),
      );
      expect(day10.dayOfCycle, equals(10));
      expect(day10.daysElapsed, equals(9));
      expect(day10.status, equals(CatheterLifespanStatus.green));
      expect(day10.isCautiRiskActive, isFalse);
      expect(day10.daysRemaining, equals(5));
    });

    test('Transitions correctly into Amber state for days 11 to 14 (replacement advisory)', () {
      // Day 11 (start of amber warning)
      final day11 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 11, 8, 0),
      );
      expect(day11.dayOfCycle, equals(11));
      expect(day11.daysElapsed, equals(10));
      expect(day11.status, equals(CatheterLifespanStatus.amber));
      expect(day11.isCautiRiskActive, isFalse);
      expect(day11.daysRemaining, equals(4));

      // Day 14 (due date day)
      final day14 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 14, 20, 0),
      );
      expect(day14.dayOfCycle, equals(14));
      expect(day14.daysElapsed, equals(13));
      expect(day14.status, equals(CatheterLifespanStatus.amber));
      expect(day14.isCautiRiskActive, isFalse);
      expect(day14.daysRemaining, equals(1));
    });

    test('Transitions correctly into Red state for days 15+ (CAUTI Risk Window active)', () {
      // Day 15 (14 full days elapsed)
      final day15 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 15, 8, 0),
      );
      expect(day15.dayOfCycle, equals(15));
      expect(day15.daysElapsed, equals(14));
      expect(day15.status, equals(CatheterLifespanStatus.red));
      expect(day15.isCautiRiskActive, isTrue);
      expect(day15.daysRemaining, equals(0));
      expect(day15.daysOverdue, equals(1));

      // Day 20 (overdue by 6 days in CAUTI risk window)
      final day20 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        asOf: DateTime.utc(2026, 9, 20, 8, 0),
      );
      expect(day20.dayOfCycle, equals(20));
      expect(day20.daysElapsed, equals(19));
      expect(day20.status, equals(CatheterLifespanStatus.red));
      expect(day20.isCautiRiskActive, isTrue);
      expect(day20.daysRemaining, equals(0));
      expect(day20.daysOverdue, equals(6));
    });

    test('Standardized 4-tier Hematuria Grade scale maps titles and clinical definitions accurately', () {
      expect(HematuriaGradeInfo.fromGrade(1).title, equals('Grade 1: Clear/Yellow'));
      expect(HematuriaGradeInfo.fromGrade(2).title, equals('Grade 2: Light Pink/Microscopic'));
      expect(HematuriaGradeInfo.fromGrade(3).title, equals('Grade 3: Red/Gross'));
      expect(HematuriaGradeInfo.fromGrade(4).title, equals('Grade 4: Dark Burgundy/Clots'));

      expect(() => HematuriaGradeInfo.fromGrade(0), throwsArgumentError);
      expect(() => HematuriaGradeInfo.fromGrade(5), throwsArgumentError);
    });

    test('CatheterMaterial enum maps lifespans and parses strings correctly', () {
      expect(CatheterMaterial.latex14Day.defaultLifespanDays, equals(14));
      expect(CatheterMaterial.latex14Day.displayName, equals('14-Day Latex'));
      expect(CatheterMaterial.silicone30Day.defaultLifespanDays, equals(30));
      expect(CatheterMaterial.silicone30Day.displayName, equals('30-Day Silicone'));
      expect(CatheterMaterial.silicone90Day.defaultLifespanDays, equals(90));
      expect(CatheterMaterial.silicone90Day.displayName, equals('90-Day Silicone'));
      expect(CatheterMaterial.custom.displayName, equals('Custom Duration'));

      expect(CatheterMaterial.fromString('latex14Day'), equals(CatheterMaterial.latex14Day));
      expect(CatheterMaterial.fromString('silicone30Day'), equals(CatheterMaterial.silicone30Day));
      expect(CatheterMaterial.fromString('silicone90Day'), equals(CatheterMaterial.silicone90Day));
      expect(CatheterMaterial.fromString('custom'), equals(CatheterMaterial.custom));
      expect(CatheterMaterial.fromString('unknown'), equals(CatheterMaterial.latex14Day));
    });

    test('30-Day Silicone catheter evaluates green, amber, and red CAUTI risk correctly', () {
      // Day 1
      final day1 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone30Day,
        asOf: DateTime.utc(2026, 9, 1, 10, 0),
      );
      expect(day1.totalLifespanDays, equals(30));
      expect(day1.dayOfCycle, equals(1));
      expect(day1.status, equals(CatheterLifespanStatus.green));
      expect(day1.isCautiRiskActive, isFalse);
      expect(day1.daysRemaining, equals(30));

      // Day 22 (still green)
      final day22 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone30Day,
        asOf: DateTime.utc(2026, 9, 22, 10, 0),
      );
      expect(day22.dayOfCycle, equals(22));
      expect(day22.status, equals(CatheterLifespanStatus.green));

      // Day 25 (approaching replacement: Amber)
      final day25 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone30Day,
        asOf: DateTime.utc(2026, 9, 25, 10, 0),
      );
      expect(day25.dayOfCycle, equals(25));
      expect(day25.status, equals(CatheterLifespanStatus.amber));
      expect(day25.isCautiRiskActive, isFalse);
      expect(day25.daysRemaining, equals(6));

      // Day 31 (Day 31 of 30: CAUTI Risk Window active)
      final day31 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone30Day,
        asOf: DateTime.utc(2026, 10, 1, 10, 0),
      );
      expect(day31.dayOfCycle, equals(31));
      expect(day31.status, equals(CatheterLifespanStatus.red));
      expect(day31.isCautiRiskActive, isTrue);
      expect(day31.daysOverdue, equals(1));
    });

    test('90-Day Silicone catheter evaluates lifespan and CAUTI risk progression', () {
      // Day 1
      final day1 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone90Day,
        asOf: DateTime.utc(2026, 9, 1, 10, 0),
      );
      expect(day1.totalLifespanDays, equals(90));
      expect(day1.dayOfCycle, equals(1));
      expect(day1.status, equals(CatheterLifespanStatus.green));

      // Day 80 (approaching replacement: Amber)
      final day80 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone90Day,
        asOf: insertionDate.add(const Duration(days: 79)),
      );
      expect(day80.dayOfCycle, equals(80));
      expect(day80.status, equals(CatheterLifespanStatus.amber));
      expect(day80.isCautiRiskActive, isFalse);

      // Day 91 (overdue: Red CAUTI)
      final day91 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.silicone90Day,
        asOf: insertionDate.add(const Duration(days: 90)),
      );
      expect(day91.dayOfCycle, equals(91));
      expect(day91.status, equals(CatheterLifespanStatus.red));
      expect(day91.isCautiRiskActive, isTrue);
      expect(day91.daysOverdue, equals(1));
    });

    test('Custom lifespan duration evaluates dynamically', () {
      final custom21 = CatheterLifespanRules.evaluateLifespan(
        insertionDate: insertionDate,
        material: CatheterMaterial.custom,
        customLifespanDays: 21,
        asOf: insertionDate.add(const Duration(days: 21)),
      );
      expect(custom21.totalLifespanDays, equals(21));
      expect(custom21.dayOfCycle, equals(22));
      expect(custom21.status, equals(CatheterLifespanStatus.red));
      expect(custom21.isCautiRiskActive, isTrue);
      expect(custom21.daysOverdue, equals(1));
    });

    test('Scheduled collection bag emptying reminders compute interval and overdue status', () {
      final inserted = DateTime.utc(2026, 9, 1, 8, 0);

      // 4-hour interval, check at 2 hours (not due)
      final status2h = CatheterLifespanRules.evaluateLifespan(
        insertionDate: inserted,
        bagEmptyingIntervalHours: 4,
        asOf: DateTime.utc(2026, 9, 1, 10, 0),
      );
      expect(status2h.bagEmptyingIntervalHours, equals(4));
      expect(status2h.nextBagEmptyingDue, equals(DateTime.utc(2026, 9, 1, 12, 0)));
      expect(status2h.isBagEmptyingDue, isFalse);
      expect(status2h.minutesUntilNextBagEmptying, equals(120));

      // Check at 4 hours (due)
      final status4h = CatheterLifespanRules.evaluateLifespan(
        insertionDate: inserted,
        bagEmptyingIntervalHours: 4,
        asOf: DateTime.utc(2026, 9, 1, 12, 0),
      );
      expect(status4h.isBagEmptyingDue, isTrue);
      expect(status4h.minutesUntilNextBagEmptying, equals(0));

      // After bag is emptied at 12:30, next due should be 16:30 for 4-hour interval
      final emptiedAt = DateTime.utc(2026, 9, 1, 12, 30);
      final statusAfterEmpty = CatheterLifespanRules.evaluateLifespan(
        insertionDate: inserted,
        lastBagEmptiedAt: emptiedAt,
        bagEmptyingIntervalHours: 4,
        asOf: DateTime.utc(2026, 9, 1, 13, 30),
      );
      expect(statusAfterEmpty.nextBagEmptyingDue, equals(DateTime.utc(2026, 9, 1, 16, 30)));
      expect(statusAfterEmpty.isBagEmptyingDue, isFalse);
      expect(statusAfterEmpty.minutesUntilNextBagEmptying, equals(180));
    });
  });
}
