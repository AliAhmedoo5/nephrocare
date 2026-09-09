import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/catheter/domain/catheter_lifespan_rules.dart';
import 'package:nephrocare/src/features/dashboard/presentation/condition_adaptive_grid.dart';
import 'package:nephrocare/src/features/fluid/domain/fluid_balance_summary.dart';
import 'package:nephrocare/src/features/profile/domain/clinical_condition.dart';
import 'package:nephrocare/src/features/profile/domain/condition_adaptive_grid_config.dart';

void main() {
  group('Domain Seam: ConditionAdaptiveGridConfig Exact 6-Card Orchestration', () {
    test('Hemodialysis configures exactly six specified clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.hemodialysis.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles[0], equals('Unified Dialysis Session'));
      expect(titles[1], equals('Blood Pressure & Paired BP'));
      expect(titles[2], equals('Fluid Hub'));
      expect(titles[3], equals('Medication Management'));
      expect(titles[4], equals('Catheter & Access Monitor'));
      expect(titles[5], equals('Modular Clinical Report'));
    });

    test('Peritoneal Dialysis configures exactly six specified clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.peritonealDialysis.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles[0], equals('Exchange Log'));
      expect(titles[1], equals('Exit-Site Inspection'));
      expect(titles[2], equals('Daily Weight'));
      expect(titles[3], equals('Blood Pressure'));
      expect(titles[4], equals('Fluid Hub'));
      expect(titles[5], equals('Medication Management'));
    });

    test('Non-Dialysis CKD configures exactly six specified clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.nonDialysisCkd.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles[0], equals('Blood Pressure & Paired BP'));
      expect(titles[1], equals('Daily Weight'));
      expect(titles[2], equals('Fluid Hub'));
      expect(titles[3], equals('Medication Management'));
      expect(titles[4], equals('Symptom Log'));
      expect(titles[5], equals('Modular Clinical Report'));
    });

    test('Urological / Catheter configures exactly six specified clinical action cards', () {
      final cards = ConditionAdaptiveGridConfig.getCardsForCondition(ClinicalCondition.urologicalCatheter.name);
      expect(cards.length, equals(6));

      final titles = cards.map((c) => c.title).toList();
      expect(titles[0], equals('Foley Catheter Lifespan'));
      expect(titles[1], equals('Fluid Hub'));
      expect(titles[2], equals('Medication Management'));
      expect(titles[3], equals('Blood Pressure'));
      expect(titles[4], equals('Symptom Log'));
      expect(titles[5], equals('Modular Clinical Report'));
    });

    test('All cards across all clinical conditions satisfy non-empty semantic contracts', () {
      for (final condition in ClinicalCondition.values) {
        final cards = ConditionAdaptiveGridConfig.getCardsForCondition(condition.name);
        expect(cards.length, equals(6));
        for (final card in cards) {
          expect(card.id, isNotEmpty);
          expect(card.title, isNotEmpty);
          expect(card.subtitle, isNotEmpty);
          expect(card.semanticLabel, isNotEmpty);
        }
      }
    });
  });

  group('Presentation Seam: ConditionAdaptiveGrid Widget Live Subtitles & Accessibility', () {
    Widget buildTestGrid({
      required String conditionName,
      FluidBalanceSummary? fluidSummary,
      CatheterLifespanSummary? catheterSummary,
      int? activeMedicationsCount,
      bool hasActiveDialysisSession = false,
      void Function(ClinicalActionCard)? onCardTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConditionAdaptiveGrid(
              conditionName: conditionName,
              fluidSummary: fluidSummary,
              catheterSummary: catheterSummary,
              activeMedicationsCount: activeMedicationsCount,
              hasActiveDialysisSession: hasActiveDialysisSession,
              onCardTap: onCardTap,
            ),
          ),
        ),
      );
    }

    testWidgets('Renders all 6 cards with minimum 48dp touch targets', (tester) async {
      await tester.pumpWidget(
        buildTestGrid(conditionName: ClinicalCondition.hemodialysis.name),
      );
      await tester.pumpAndSettle();

      final cards = find.byType(InkWell);
      expect(cards, findsNWidgets(6));

      for (int i = 0; i < 6; i++) {
        final cardElement = cards.at(i);
        final size = tester.getSize(cardElement);
        expect(size.height, greaterThanOrEqualTo(48.0));
        expect(size.width, greaterThanOrEqualTo(48.0));
      }
    });

    testWidgets('Dynamically injects live fluid balance plain language summary into Fluid Hub card', (tester) async {
      final summary = FluidBalanceSummary(
        totalIntakeMl: 1200,
        dailyFluidAllowanceMl: 1500,
        totalUrineOutputMl: 400,
        machineUltrafiltrationMl: 1800,
      );

      await tester.pumpWidget(
        buildTestGrid(
          conditionName: ClinicalCondition.hemodialysis.name,
          fluidSummary: summary,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fluid Hub'), findsOneWidget);
      expect(find.text(summary.plainLanguageSummary), findsOneWidget);
    });

    testWidgets('Dynamically updates Medication Management subtitle with live active medication count', (tester) async {
      await tester.pumpWidget(
        buildTestGrid(
          conditionName: ClinicalCondition.hemodialysis.name,
          activeMedicationsCount: 4,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medication Management'), findsOneWidget);
      expect(find.textContaining('4 active medications & binders'), findsOneWidget);
    });

    testWidgets('Dynamically updates Catheter & Access Monitor and Foley Catheter Lifespan with catheter risk state', (tester) async {
      final now = DateTime.now().toUtc();
      final catheterSummary = CatheterLifespanSummary(
        insertionDate: now.subtract(const Duration(days: 32)),
        replacementDueDate: now.subtract(const Duration(days: 2)),
        asOf: now,
        dayOfCycle: 33,
        daysElapsed: 32,
        daysRemaining: -2,
        daysOverdue: 2,
        status: CatheterLifespanStatus.red,
        isCautiRiskActive: true,
        material: CatheterMaterial.silicone30Day,
        totalLifespanDays: 30,
      );

      // 1. Foley Catheter Lifespan in Urological / Catheter
      await tester.pumpWidget(
        buildTestGrid(
          conditionName: ClinicalCondition.urologicalCatheter.name,
          catheterSummary: catheterSummary,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Foley Catheter Lifespan'), findsOneWidget);
      expect(find.textContaining('Day 33 of 30 • CAUTI Risk Window Active'), findsOneWidget);

      // 2. Catheter & Access Monitor in Hemodialysis
      await tester.pumpWidget(
        buildTestGrid(
          conditionName: ClinicalCondition.hemodialysis.name,
          catheterSummary: catheterSummary,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catheter & Access Monitor'), findsOneWidget);
      expect(find.textContaining('Day 33 of 30 • CAUTI Risk Window Active'), findsOneWidget);
    });

    testWidgets('Dynamically updates Unified Dialysis Session subtitle when session is actively in progress', (tester) async {
      await tester.pumpWidget(
        buildTestGrid(
          conditionName: ClinicalCondition.hemodialysis.name,
          hasActiveDialysisSession: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unified Dialysis Session'), findsOneWidget);
      expect(find.textContaining('Session in progress • Tap to resume/checkout'), findsOneWidget);
    });

    testWidgets('Tapping on a card triggers onCardTap callback with effective card', (tester) async {
      ClinicalActionCard? tappedCard;

      await tester.pumpWidget(
        buildTestGrid(
          conditionName: ClinicalCondition.hemodialysis.name,
          onCardTap: (card) {
            tappedCard = card;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unified Dialysis Session'));
      await tester.pumpAndSettle();

      expect(tappedCard, isNotNull);
      expect(tappedCard!.title, equals('Unified Dialysis Session'));
    });
  });
}
