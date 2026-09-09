import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/sync/presentation/animated_qr_display_widget.dart';
import 'package:nephrocare/src/features/sync/presentation/offline_peer_sync_screen.dart';

void main() {
  group('Presentation & Application UI Seam: Triple-Channel Offline Peer Sync', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Widget buildTestApp(Widget home) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
        ],
        child: MaterialApp(
          home: home,
        ),
      );
    }

    testWidgets('DashboardScreen AppBar opens OfflinePeerSyncScreen cleanly', (tester) async {
      final patient = await harness.createPatient(
        name: 'Ada Lovelace',
        diagnosis: 'hemodialysis',
      );

      await tester.pumpWidget(buildTestApp(DashboardScreen(patient: patient)));
      // DashboardScreen watches Drift reactive streams that never quiesce —
      // use pump() instead of pumpAndSettle() to avoid hanging.
      await tester.pump();
      await tester.pump();

      final syncButton = find.byKey(const Key('open_peer_sync_button'));
      expect(syncButton, findsOneWidget);

      await tester.tap(syncButton);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(OfflinePeerSyncScreen), findsOneWidget);
      expect(find.text('Offline Peer-to-Peer Sync'), findsOneWidget);
    });

    testWidgets('OfflinePeerSyncScreen renders Send & Receive modes with 3 channels', (tester) async {
      final patient = await harness.createPatient(
        name: 'Ada Lovelace',
        diagnosis: 'hemodialysis',
      );

      await tester.pumpWidget(buildTestApp(OfflinePeerSyncScreen(patient: patient)));
      await tester.pumpAndSettle();

      // Verify the 3 complementary offline channels are present
      expect(find.text('Animated Multi-Frame QR'), findsOneWidget);
      expect(find.text('Local Wi-Fi Handshake'), findsOneWidget);
      expect(find.text('Encrypted Patient Export (.nephro)'), findsOneWidget);

      // Verify Export / Send and Import / Receive tabs
      expect(find.text('Send / Export'), findsOneWidget);
      expect(find.text('Receive / Import'), findsOneWidget);
    });

    testWidgets('Send mode starts Animated Multi-Frame QR visual streaming with cycler', (tester) async {
      final patient = await harness.createPatient(
        name: 'Ada Lovelace',
        diagnosis: 'hemodialysis',
      );

      for (int i = 0; i < 5; i++) {
        await harness.recordDialysisSession(
          patientId: patient.id,
          sessionType: 'hemodialysis',
          startedAt: DateTime.utc(2026, 3, 1 + i),
          notes: 'Dialysis session clinical note number $i with detailed treatment observations',
        );
      }

      await tester.pumpWidget(buildTestApp(OfflinePeerSyncScreen(patient: patient)));
      await tester.pumpAndSettle();

      final streamButton = find.byKey(const Key('start_animated_qr_button'));
      await tester.ensureVisible(streamButton);
      await tester.tap(streamButton);
      await tester.pumpAndSettle();

      // Cycler widget appears with frame counter and QR
      expect(find.byType(AnimatedQrDisplayWidget), findsOneWidget);
      expect(find.textContaining('Frame 1 of'), findsOneWidget);

      // Advance next frame
      final nextButton = find.byKey(const Key('qr_next_frame_button'));
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Frame 2 of'), findsOneWidget);
    });

    testWidgets('Send mode hosts Local Wi-Fi Handshake ephemeral server and displays pairing info', (tester) async {
      final patient = await harness.createPatient(
        name: 'Ada Lovelace',
        diagnosis: 'hemodialysis',
      );

      await tester.pumpWidget(buildTestApp(OfflinePeerSyncScreen(patient: patient)));
      await tester.pumpAndSettle();

      final startHostButton = find.byKey(const Key('start_wifi_host_button'));
      await tester.ensureVisible(startHostButton);
      await tester.tap(startHostButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Local Wi-Fi Host Active'), findsOneWidget);
      final stopButton = find.byKey(const Key('stop_wifi_host_button'));
      expect(stopButton, findsOneWidget);

      // Stop server cleanly
      await tester.ensureVisible(stopButton);
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('start_wifi_host_button')), findsOneWidget);
    });
  });
}
