import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/database/database_provider.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nephrocare/src/features/sync/domain/animated_qr_codec.dart';
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
      await tester.pumpAndSettle();

      final syncButton = find.byKey(const Key('open_peer_sync_button'));
      expect(syncButton, findsOneWidget);

      await tester.tap(syncButton);
      await tester.pumpAndSettle();

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

    testWidgets('Receive mode in OfflinePeerSyncScreen ingests frames as Caregiver Mirror and displays merge summary with complete dataset', (tester) async {
      final sourceHarness = createNephroTestHarness();
      addTearDown(() => sourceHarness.dispose());

      final t0 = DateTime.utc(2026, 3, 1, 8, 0);
      final sourcePatient = await sourceHarness.createPatient(
        name: 'Grace Hopper',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 58.0,
        dailyFluidAllowanceMl: 1000,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        createdAt: t0,
        updatedAt: t0,
      );

      await sourceHarness.recordDialysisSession(
        patientId: sourcePatient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        endedAt: t0.add(const Duration(hours: 4)),
        preWeightKg: 60.0,
        postWeightKg: 58.1,
        status: 'completed',
        createdAt: t0,
        updatedAt: t0,
      );

      final med = await sourceHarness.createMedication(
        patientId: sourcePatient.id,
        name: 'Sevelamer',
        dosage: '800mg',
        frequency: 'TID with meals',
        isPhosphateBinder: true,
        createdAt: t0,
        updatedAt: t0,
      );

      final admin = await sourceHarness.recordMedicationAdministration(
        patientId: sourcePatient.id,
        medicationId: med.id,
        medicationName: med.name,
        dosage: med.dosage,
        administeredAt: t0,
      );

      await sourceHarness.recordBaselineBloodPressure(
        patientId: sourcePatient.id,
        medicationAdministrationId: admin.id,
        medicationName: med.name,
        systolic: 145,
        diastolic: 90,
        pulse: 75,
        armUsed: 'rightArm',
        recordedAt: t0,
      );

      await sourceHarness.recordCatheterEvent(
        patientId: sourcePatient.id,
        catheterType: 'foley',
        insertionDate: t0,
        replacementDueDate: t0.add(const Duration(days: 30)),
        status: 'active',
        material: 'silicone30Day',
        lifespanDays: 30,
        bagEmptyingIntervalHours: 8,
        lastBagEmptiedAt: t0,
        createdAt: t0,
        updatedAt: t0,
      );

      final bundle = await sourceHarness.exportPatientSyncBundle(sourcePatient.id);
      final jsonPayload = jsonEncode(bundle.toJson());
      final frames = AnimatedQrEncoder.encode(jsonPayload, chunkSize: 200);

      // Target device begins on empty database with a placeholder user or direct screen
      final localPatient = await harness.createPatient(
        name: 'Caregiver Device User',
        diagnosis: 'nonDialysisCkd',
      );

      await tester.pumpWidget(buildTestApp(OfflinePeerSyncScreen(patient: localPatient)));
      await tester.pumpAndSettle();

      // Switch to Receive / Import tab
      await tester.tap(find.text('Receive / Import'));
      await tester.pumpAndSettle();

      // Toggle Caregiver Mirror checkbox
      final caregiverCheckbox = find.byKey(const Key('caregiver_mirror_checkbox'));
      await tester.ensureVisible(caregiverCheckbox);
      await tester.tap(caregiverCheckbox);
      await tester.pumpAndSettle();

      // Ingest each frame
      for (final frame in frames) {
        final inputField = find.byKey(const Key('manual_frame_input'));
        await tester.ensureVisible(inputField);
        await tester.enterText(inputField, frame.toWireFormat());

        final ingestButton = find.byKey(const Key('ingest_frame_button'));
        await tester.ensureVisible(ingestButton);
        await tester.tap(ingestButton);
        await tester.pumpAndSettle();
      }

      // Verify UI displays successful merge summary
      expect(find.text('Records Ingested Successfully'), findsOneWidget);
      expect(find.textContaining('Inserted:'), findsOneWidget);

      // Verify Target Database state reflects Caregiver Mirror profile and all clinical records
      final importedPatient = await harness.getPatient(sourcePatient.id);
      expect(importedPatient, isNotNull);
      expect(importedPatient!.name, equals('Grace Hopper'));
      expect(importedPatient.isCaregiverMirror, isTrue);

      final importedSessions = await harness.getDialysisSessions(sourcePatient.id);
      expect(importedSessions.length, equals(1));
      expect(importedSessions.first.status, equals('completed'));

      final importedMeds = await harness.getAllMedications(sourcePatient.id);
      expect(importedMeds.length, equals(1));
      expect(importedMeds.first.name, equals('Sevelamer'));

      final importedAdmins = await harness.getMedicationAdministrations(sourcePatient.id);
      expect(importedAdmins.length, equals(1));

      final importedBp = await harness.getBloodPressureLogs(sourcePatient.id);
      expect(importedBp.length, equals(1));
      expect(importedBp.first.isPairedAssessment, isTrue);

      final importedCatheter = await harness.getActiveCatheter(sourcePatient.id);
      expect(importedCatheter, isNotNull);
      expect(importedCatheter!.material, equals('silicone30Day'));
    });
  });
}
