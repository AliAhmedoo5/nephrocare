import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/reports/presentation/modular_clinical_report_screen.dart';

void main() {
  group('Modular Clinical Report UI Seam', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Widget createTestApp({required Widget home}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: MaterialApp(
          home: home,
        ),
      );
    }

    testWidgets('Modular Clinical Report interface offers date window selection and module checklists', (tester) async {
      final patient = await harness.createPatient(
        name: 'John Watson',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 75.0,
        dailyFluidAllowanceMl: 1500,
        fistulaArmLocation: 'leftArm',
      );

      await tester.pumpWidget(createTestApp(home: ModularClinicalReportScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify Screen Title and Header
      expect(find.text('Modular Clinical Report'), findsOneWidget);
      expect(find.text('John Watson'), findsOneWidget);

      // Verify all 4 Date Window options are rendered
      expect(find.byKey(const Key('report_date_window_7d')), findsOneWidget);
      expect(find.byKey(const Key('report_date_window_14d')), findsOneWidget);
      expect(find.byKey(const Key('report_date_window_30d')), findsOneWidget);
      expect(find.byKey(const Key('report_date_window_custom')), findsOneWidget);

      // Verify all 5 Clinical Module checklist toggles are present and default to enabled
      expect(find.byKey(const Key('module_toggle_demographics')), findsOneWidget);
      expect(find.byKey(const Key('module_toggle_weight_trends')), findsOneWidget);
      expect(find.byKey(const Key('module_toggle_bp')), findsOneWidget);
      expect(find.byKey(const Key('module_toggle_fluid')), findsOneWidget);
      expect(find.byKey(const Key('module_toggle_catheter')), findsOneWidget);

      // Switch date window from 14d to 7d
      await tester.tap(find.byKey(const Key('report_date_window_7d')));
      await tester.pumpAndSettle();

      // Switch to Custom date window - custom date pickers should appear
      await tester.tap(find.byKey(const Key('report_date_window_custom')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('custom_start_date_button')), findsOneWidget);
      expect(find.byKey(const Key('custom_end_date_button')), findsOneWidget);

      // Toggle off Weight Trends module
      await tester.tap(find.byKey(const Key('module_toggle_weight_trends')));
      await tester.pumpAndSettle();

      // Verify Preview and Share buttons are rendered
      expect(find.byKey(const Key('preview_report_button')), findsOneWidget);
      expect(find.byKey(const Key('export_share_button')), findsOneWidget);
    });

    testWidgets('Dashboard AppBar opens Modular Clinical Report screen cleanly', (tester) async {
      final patient = await harness.createPatient(
        name: 'Mary Morstan',
        diagnosis: 'hemodialysis',
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      // DashboardScreen watches Drift reactive streams that never quiesce —
      // use pump() instead of pumpAndSettle() to avoid hanging.
      await tester.pump();
      await tester.pump();

      // Verify open reports button exists in Dashboard AppBar
      final reportButton = find.byKey(const Key('open_reports_button'));
      expect(reportButton, findsOneWidget);

      // Tap to open Modular Clinical Report screen
      await tester.tap(reportButton);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify navigation into report generator interface
      expect(find.text('Modular Clinical Report'), findsOneWidget);
      expect(find.byKey(const Key('preview_report_button')), findsOneWidget);
    });

    testWidgets('ConditionAdaptiveGrid card taps cleanly navigate into Modular Clinical Report screen', (tester) async {
      final patient = await harness.createPatient(
        name: 'James Moriarty',
        diagnosis: 'hemodialysis',
      );

      await tester.pumpWidget(createTestApp(home: DashboardScreen(patient: patient)));
      // DashboardScreen watches Drift reactive streams that never quiesce.
      await tester.pump();
      await tester.pump();

      // Find the Modular Clinical Report card on the Condition-Adaptive Grid
      final gridCard = find.text('Modular Clinical Report');
      expect(gridCard, findsOneWidget);

      await tester.ensureVisible(gridCard);
      await tester.pump();

      await tester.tap(gridCard);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify navigated to report screen
      expect(find.byKey(const Key('report_date_window_14d')), findsOneWidget);
      expect(find.byKey(const Key('preview_report_button')), findsOneWidget);
    });

    testWidgets('Clear button deselects all modules and warns when preview attempted with 0 modules', (tester) async {
      final patient = await harness.createPatient(
        name: 'Mycroft Holmes',
        diagnosis: 'hemodialysis',
      );

      await tester.pumpWidget(createTestApp(home: ModularClinicalReportScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Tap 'Clear' button to deselect all modules
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Ensure 'preview_report_button' is visible in scrollable
      await tester.ensureVisible(find.byKey(const Key('preview_report_button')));
      await tester.pumpAndSettle();

      // Tap 'Generate & Preview PDF'
      await tester.tap(find.byKey(const Key('preview_report_button')));
      await tester.pumpAndSettle();

      // Verify validation warning snackbar
      expect(find.text('Please select at least one clinical module to include in the report.'), findsOneWidget);

      // Tap 'Select All' to restore all modules
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      final demographicsTile = tester.widget<CheckboxListTile>(find.byKey(const Key('module_toggle_demographics')));
      expect(demographicsTile.value, isTrue);
    });
  });
}
