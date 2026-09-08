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
  });
}
