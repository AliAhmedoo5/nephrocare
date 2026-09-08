import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/sync/domain/patient_sync_bundle.dart';
import 'package:nephrocare/src/features/sync/domain/local_wifi_handshake.dart';

void main() {
  group('Channel 2: Local Wi-Fi Handshake HTTP Server Seam', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Hosts ephemeral on-device HTTP server with QR-paired token and transfers dataset in <1s', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final patient = await harness.createPatient(
        name: 'Isaac Newton',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 75.0,
        dailyFluidAllowanceMl: 1100,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        createdAt: t0,
        updatedAt: t0,
      );

      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        preWeightKg: 77.2,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: harness.database,
        patientId: patient.id,
      );

      // Start host on loopback address for deterministic isolated unit testing
      final host = await LocalWifiHandshakeHost.start(
        bundle: bundle,
        address: InternetAddress.loopbackIPv4,
        port: 0, // OS assigns ephemeral open port
      );
      addTearDown(() => host.close());

      final pairingInfo = host.pairingInfo;
      expect(pairingInfo.port, greaterThan(0));
      expect(pairingInfo.authToken, isNotEmpty);
      expect(pairingInfo.toQrPayload(), contains(pairingInfo.authToken));

      // Client connects with valid pairing token
      final stopwatch = Stopwatch()..start();
      final client = LocalWifiHandshakeClient();
      final receivedBundle = await client.fetchBundle(
        host: pairingInfo.host,
        port: pairingInfo.port,
        authToken: pairingInfo.authToken,
      );
      stopwatch.stop();

      // Sub-second transfer verification
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      expect(receivedBundle.patient.id, equals(patient.id));
      expect(receivedBundle.patient.name, equals('Isaac Newton'));
      expect(receivedBundle.dialysisSessions.length, equals(1));
    });

    test('Rejects unauthorized client requests when token is invalid or missing', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final patient = await harness.createPatient(
        name: 'Isaac Newton',
        diagnosis: 'hemodialysis',
        createdAt: t0,
        updatedAt: t0,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: harness.database,
        patientId: patient.id,
      );

      final host = await LocalWifiHandshakeHost.start(
        bundle: bundle,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(() => host.close());

      final client = LocalWifiHandshakeClient();

      expect(
        () async => await client.fetchBundle(
          host: host.pairingInfo.host,
          port: host.pairingInfo.port,
          authToken: 'BAD_UNAUTHORIZED_TOKEN',
        ),
        throwsA(isA<LocalWifiHandshakeAuthException>()),
      );
    });
  });
}
