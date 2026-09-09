import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/sync/domain/animated_qr_codec.dart';
import 'package:nephrocare/src/features/sync/domain/local_wifi_handshake.dart';
import 'package:nephrocare/src/features/sync/domain/nephro_archive_codec.dart';
import 'package:nephrocare/src/features/sync/domain/patient_sync_bundle.dart';

void main() {
  group('Unified Offline Exchange Seam: Triple-Channel Round-Trip Verification', () {
    late NephroTestHarness sourceHarness;
    late NephroTestHarness targetHarness;

    setUp(() {
      sourceHarness = createNephroTestHarness();
      targetHarness = createNephroTestHarness();
    });

    tearDown(() async {
      await sourceHarness.dispose();
      await targetHarness.dispose();
    });

    Future<String> populateFullClinicalDataset(NephroTestHarness h) async {
      final t0 = DateTime.utc(2026, 3, 1, 8, 0);
      final patient = await h.createPatient(
        name: 'Margaret Hamilton',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 62.0,
        dailyFluidAllowanceMl: 1000,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        createdAt: t0,
        updatedAt: t0,
      );

      await h.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        endedAt: t0.add(const Duration(hours: 4)),
        preWeightKg: 64.2,
        postWeightKg: 62.1,
        calculatedInterdialyticWeightGainKg: 2.2,
        calculatedUltrafiltrationGoalMl: 2200,
        calculatedPostWeightDifferenceKg: 0.1,
        actualFluidRemovedMl: 2100,
        notes: 'Smooth treatment',
        symptoms: 'none',
        status: 'completed',
        createdAt: t0,
        updatedAt: t0,
      );

      await h.createMedication(
        patientId: patient.id,
        name: 'Calcium Acetate',
        dosage: '667mg',
        frequency: 'TID with meals',
        isPhosphateBinder: true,
        createdAt: t0,
        updatedAt: t0,
      );

      final antiHypertensive = await h.createMedication(
        patientId: patient.id,
        name: 'Losartan Potassium',
        dosage: '50mg',
        frequency: 'Daily',
        isAntiHypertensive: true,
        createdAt: t0,
        updatedAt: t0,
      );

      final admin = await h.recordMedicationAdministration(
        patientId: patient.id,
        medicationId: antiHypertensive.id,
        medicationName: antiHypertensive.name,
        dosage: antiHypertensive.dosage,
        administeredAt: t0,
      );

      final baselineBp = await h.recordBaselineBloodPressure(
        patientId: patient.id,
        medicationAdministrationId: admin.id,
        medicationName: antiHypertensive.name,
        systolic: 150,
        diastolic: 92,
        pulse: 74,
        armUsed: 'rightArm',
        recordedAt: t0,
      );

      await h.recordFollowUpBloodPressure(
        patientId: patient.id,
        pairedAssessmentId: baselineBp.pairedAssessmentId!,
        systolic: 132,
        diastolic: 80,
        pulse: 70,
        armUsed: 'rightArm',
        recordedAt: t0.add(const Duration(minutes: 30)),
      );

      await h.recordFluidIntake(
        patientId: patient.id,
        volumeMl: 200,
        beverageType: 'Tea',
        phosphateBinderTaken: true,
        recordedAt: t0.add(const Duration(hours: 1)),
      );

      await h.recordFluidOutput(
        patientId: patient.id,
        volumeMl: 150,
        outputType: 'urine',
        hematuriaGrade: 1,
        recordedAt: t0.add(const Duration(hours: 2)),
      );

      await h.recordCatheterEvent(
        patientId: patient.id,
        catheterType: 'foley',
        insertionDate: t0,
        replacementDueDate: t0.add(const Duration(days: 30)),
        status: 'active',
        notes: 'Silicone 16Fr',
        material: 'silicone30Day',
        lifespanDays: 30,
        bagEmptyingIntervalHours: 6,
        lastBagEmptiedAt: t0,
        createdAt: t0,
        updatedAt: t0,
      );

      await h.recordAccessInspection(
        patientId: patient.id,
        accessType: 'arteriovenousFistula',
        anatomicalLocation: 'leftArm',
        thrillPresent: true,
        bruitPresent: true,
        rednessPresent: false,
        swellingPresent: false,
        dischargePresent: false,
        painPresent: false,
        recordedAt: t0,
      );

      return patient.id;
    }

    test('Channel 1: Animated Multi-Frame QR round-trip export, reassembly, and Drift merge', () async {
      final patientId = await populateFullClinicalDataset(sourceHarness);
      final sourceBundle = await sourceHarness.exportPatientSyncBundle(patientId);

      // Encode into cycling frames
      final jsonPayload = jsonEncode(sourceBundle.toJson());
      final frames = AnimatedQrEncoder.encode(jsonPayload, chunkSize: 120);
      expect(frames.length, greaterThan(3));

      // Simulate optical camera scan receiving frames in random out-of-order sequence
      final reassembler = AnimatedQrReassembler();
      final wireList = frames.map((f) => f.toWireFormat()).toList()..shuffle();

      for (final wireFrame in wireList) {
        reassembler.addFrame(wireFrame);
      }

      expect(reassembler.isComplete, isTrue);
      final receivedJson = reassembler.reassembledPayload!;
      final receivedBundle = PatientSyncBundle.fromJson(jsonDecode(receivedJson) as Map<String, dynamic>);

      // Merge into clean target database
      final mergeResult = await targetHarness.mergePatientSyncBundle(receivedBundle, asCaregiverMirror: true);

      expect(mergeResult.patientsInserted, equals(1));
      expect(mergeResult.medicationsInserted, equals(2));
      expect(mergeResult.medicationAdministrationsInserted, equals(1));
      expect(mergeResult.dialysisSessionsInserted, equals(1));
      expect(mergeResult.bloodPressureLogsInserted, equals(2));
      expect(mergeResult.fluidIntakeLogsInserted, equals(1));
      expect(mergeResult.fluidOutputLogsInserted, equals(1));
      expect(mergeResult.catheterEventsInserted, equals(1));
      expect(mergeResult.accessInspectionsInserted, equals(1));

      // Verify relational integrity on target device
      final targetPatient = await targetHarness.getPatient(patientId);
      expect(targetPatient, isNotNull);
      expect(targetPatient!.name, equals('Margaret Hamilton'));
      expect(targetPatient.isCaregiverMirror, isTrue);

      final targetSessions = await targetHarness.getDialysisSessions(patientId);
      expect(targetSessions.length, equals(1));
      expect(targetSessions.first.calculatedUltrafiltrationGoalMl, equals(2200));
      expect(targetSessions.first.status, equals('completed'));

      final targetMeds = await targetHarness.getAllMedications(patientId);
      expect(targetMeds.length, equals(2));
      expect(targetMeds.any((m) => m.name == 'Calcium Acetate' && m.isPhosphateBinder), isTrue);
      expect(targetMeds.any((m) => m.name == 'Losartan Potassium' && m.isAntiHypertensive), isTrue);

      final targetAdmins = await targetHarness.getMedicationAdministrations(patientId);
      expect(targetAdmins.length, equals(1));
      expect(targetAdmins.first.medicationName, equals('Losartan Potassium'));

      final targetBp = await targetHarness.getBloodPressureLogs(patientId);
      expect(targetBp.length, equals(2));
      final followUp = targetBp.firstWhere((b) => b.pairedRole == 'followUp');
      expect(followUp.systolic, equals(132));
      expect(followUp.systolicDelta, equals(-18));

      final targetCatheter = await targetHarness.getActiveCatheter(patientId);
      expect(targetCatheter, isNotNull);
      expect(targetCatheter!.material, equals('silicone30Day'));
      expect(targetCatheter.lifespanDays, equals(30));
      expect(targetCatheter.bagEmptyingIntervalHours, equals(6));

      final targetInspections = await targetHarness.getAccessInspections(patientId);
      expect(targetInspections.length, equals(1));
      expect(targetInspections.first.thrillPresent, isTrue);
    });

    test('Channel 2: Local Wi-Fi Handshake round-trip export, HTTP transfer, and Drift merge', () async {
      final patientId = await populateFullClinicalDataset(sourceHarness);
      final sourceBundle = await sourceHarness.exportPatientSyncBundle(patientId);

      // Start ephemeral host
      final host = await LocalWifiHandshakeHost.start(
        bundle: sourceBundle,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(() => host.close());

      // Client pairs and downloads
      final client = LocalWifiHandshakeClient();
      final receivedBundle = await client.fetchBundle(
        host: host.pairingInfo.host,
        port: host.pairingInfo.port,
        authToken: host.pairingInfo.authToken,
      );

      // Ingest into target database
      final mergeResult = await targetHarness.mergePatientSyncBundle(receivedBundle);
      expect(mergeResult.patientsInserted, equals(1));
      expect(mergeResult.medicationsInserted, equals(2));
      expect(mergeResult.medicationAdministrationsInserted, equals(1));
      expect(mergeResult.dialysisSessionsInserted, equals(1));
      expect(mergeResult.bloodPressureLogsInserted, equals(2));
      expect(mergeResult.catheterEventsInserted, equals(1));

      final targetPatient = await targetHarness.getPatient(patientId);
      expect(targetPatient!.name, equals('Margaret Hamilton'));

      final targetMeds = await targetHarness.getAllMedications(patientId);
      expect(targetMeds.length, equals(2));
    });

    test('Channel 3: Encrypted Patient Export (.nephro) round-trip file export, AES decryption, and Drift merge', () async {
      final patientId = await populateFullClinicalDataset(sourceHarness);
      final sourceBundle = await sourceHarness.exportPatientSyncBundle(patientId);

      const passphrase = 'DoctorPassphrase2026!';
      final nephroFileBytes = await NephroArchiveCodec.encryptBundle(sourceBundle, passphrase: passphrase);

      // Target device receives and decrypts .nephro archive
      final decryptedBundle = await NephroArchiveCodec.decryptBundle(nephroFileBytes, passphrase: passphrase);

      final mergeResult = await targetHarness.mergePatientSyncBundle(decryptedBundle, asCaregiverMirror: true);
      expect(mergeResult.patientsInserted, equals(1));
      expect(mergeResult.medicationsInserted, equals(2));
      expect(mergeResult.medicationAdministrationsInserted, equals(1));
      expect(mergeResult.dialysisSessionsInserted, equals(1));
      expect(mergeResult.bloodPressureLogsInserted, equals(2));
      expect(mergeResult.accessInspectionsInserted, equals(1));

      final targetPatient = await targetHarness.getPatient(patientId);
      expect(targetPatient!.name, equals('Margaret Hamilton'));
      expect(targetPatient.isCaregiverMirror, isTrue);

      final targetAdmins = await targetHarness.getMedicationAdministrations(patientId);
      expect(targetAdmins.length, equals(1));
      expect(targetAdmins.first.medicationName, equals('Losartan Potassium'));
    });
  });
}
