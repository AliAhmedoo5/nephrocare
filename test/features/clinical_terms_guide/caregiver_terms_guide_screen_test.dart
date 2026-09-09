import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/clinical_terms_guide/presentation/caregiver_terms_guide_screen.dart';

void main() {
  group('Presentation Seam: CaregiverTermsGuideScreen UI', () {
    Widget buildTestHarness({String? initialTermId}) {
      return MaterialApp(
        home: CaregiverTermsGuideScreen(
          initialTermId: initialTermId,
        ),
      );
    }

    testWidgets('Renders all terms by default and allows live search filtering', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('Caregiver & Clinical Terms Guide'), findsOneWidget);
      expect(find.byKey(const Key('search_terms_input')), findsOneWidget);

      // Verify presence of terms cards
      expect(find.byKey(const Key('guide_term_card_prescribed_dry_weight')), findsOneWidget);
      expect(find.byKey(const Key('guide_term_card_idwg')), findsOneWidget);

      // Search for specific concept 'CAUTI'
      await tester.enterText(find.byKey(const Key('search_terms_input')), 'CAUTI');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('guide_term_card_cauti_risk_window')), findsOneWidget);
      expect(find.byKey(const Key('guide_term_card_prescribed_dry_weight')), findsNothing);

      // Clear search via clear button
      final clearBtn = find.byKey(const Key('clear_search_button'));
      expect(clearBtn, findsOneWidget);

      final clearSize = tester.getSize(clearBtn);
      expect(clearSize.width, greaterThanOrEqualTo(48.0));
      expect(clearSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('guide_term_card_prescribed_dry_weight')), findsOneWidget);
    });

    testWidgets('Category chips filter terms to specific clinical grouping', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Tap 'Fluid & Urology' filter chip
      final fluidChip = find.byKey(const Key('category_chip_fluidUrology'));
      expect(fluidChip, findsOneWidget);

      await tester.tap(fluidChip);
      await tester.pumpAndSettle();

      // Should show fluid concepts and hide renal-only concepts
      expect(find.byKey(const Key('guide_term_card_native_urine_balance')), findsOneWidget);
      expect(find.byKey(const Key('guide_term_card_dialytic_fluid_balance')), findsOneWidget);
      expect(find.byKey(const Key('guide_term_card_prescribed_dry_weight')), findsNothing);

      // Reset to all
      await tester.tap(find.byKey(const Key('category_chip_all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('guide_term_card_prescribed_dry_weight')), findsOneWidget);
    });

    testWidgets('Displays empty state with helpful message when search has no matches', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search_terms_input')), 'xyzNonExistentMedicalTerm123');
      await tester.pumpAndSettle();

      expect(find.text('No matching clinical terms found'), findsOneWidget);
    });

    testWidgets('Highlights initial term when navigated with initialTermId', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestHarness(initialTermId: 'hematuria_grade'));
      await tester.pumpAndSettle();

      final hematuriaCard = find.byKey(const Key('guide_term_card_hematuria_grade'));
      expect(hematuriaCard, findsOneWidget);
    });
  });
}
