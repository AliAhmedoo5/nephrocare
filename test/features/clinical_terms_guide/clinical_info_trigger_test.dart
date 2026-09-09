import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/clinical_terms_guide/presentation/caregiver_terms_guide_screen.dart';
import 'package:nephrocare/src/features/clinical_terms_guide/presentation/clinical_info_trigger.dart';

void main() {
  group('Presentation Seam: ClinicalInfoTrigger & Modal Bottom Sheet', () {
    Widget buildTestHarness({required Widget child}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: child,
          ),
        ),
      );
    }

    testWidgets('ClinicalInfoTrigger renders accessible 48dp button and displays modal bottom sheet on tap',
        (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const ClinicalInfoTrigger(
            termId: 'idwg',
            key: Key('idwg_info_trigger'),
          ),
        ),
      );

      // Verify trigger exists
      final triggerFinder = find.byKey(const Key('idwg_info_trigger'));
      expect(triggerFinder, findsOneWidget);

      // Verify touch target is at least 48x48 dp
      final size = tester.getSize(triggerFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      // Tap trigger to open modal bottom sheet
      await tester.tap(triggerFinder);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with plain language explanation and safe range
      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.text('Interdialytic Weight Gain (IDWG)'), findsWidgets);
      expect(find.textContaining('fluid weight accumulated'), findsOneWidget);
      expect(find.textContaining('< 2.0 to 2.5 kg'), findsOneWidget);
      expect(find.text('Why It Matters'), findsOneWidget);

      // Verify "Open Full Terms Guide" button is present and navigates to CaregiverTermsGuideScreen
      final guideButton = find.byKey(const Key('bottom_sheet_open_full_guide_button'));
      expect(guideButton, findsOneWidget);

      await tester.ensureVisible(guideButton);
      await tester.tap(guideButton);
      await tester.pumpAndSettle();

      expect(find.byType(CaregiverTermsGuideScreen), findsOneWidget);
    });

    testWidgets('Modal bottom sheet can be dismissed via close button without workflow disruption',
        (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const ClinicalInfoTrigger(
            termId: 'cauti_risk_window',
            key: Key('cauti_info_trigger'),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('cauti_info_trigger')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsOneWidget);
      expect(find.textContaining('CAUTI Risk Window'), findsWidgets);

      // Tap dismiss/close button
      final closeButton = find.byKey(const Key('bottom_sheet_close_button'));
      expect(closeButton, findsOneWidget);

      final closeSize = tester.getSize(closeButton);
      expect(closeSize.width, greaterThanOrEqualTo(48.0));
      expect(closeSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify bottom sheet is dismissed
      expect(find.byKey(const Key('clinical_contextual_bottom_sheet')), findsNothing);
      expect(find.byKey(const Key('cauti_info_trigger')), findsOneWidget);
    });
  });
}
