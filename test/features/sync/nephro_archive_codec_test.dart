import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/core/testing/test_harness.dart';
import 'package:nephrocare/src/features/sync/domain/patient_sync_bundle.dart';
import 'package:nephrocare/src/features/sync/domain/nephro_archive_codec.dart';

void main() {
  group('Channel 3: Encrypted Patient Export (.nephro) Seam', () {
    late NephroTestHarness harness;

    setUp(() {
      harness = createNephroTestHarness();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Encrypts PatientSyncBundle into AES-256-GCM .nephro archive and decrypts with passphrase', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final patient = await harness.createPatient(
        name: 'Grace Hopper',
        diagnosis: 'hemodialysis',
        prescribedDryWeightKg: 58.0,
        dailyFluidAllowanceMl: 900,
        vascularAccessType: 'arteriovenousFistula',
        fistulaArmLocation: 'leftArm',
        createdAt: t0,
        updatedAt: t0,
      );

      await harness.recordDialysisSession(
        patientId: patient.id,
        sessionType: 'hemodialysis',
        startedAt: t0,
        preWeightKg: 60.1,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: harness.database,
        patientId: patient.id,
      );

      const passphrase = 'ClinicianSecurePassphrase!2026';

      // Encrypt to .nephro archive bytes
      final archiveBytes = await NephroArchiveCodec.encryptBundle(bundle, passphrase: passphrase);

      expect(archiveBytes, isNotNull);
      expect(archiveBytes.length, greaterThan(52));
      // Magic header check
      expect(utf8.decode(archiveBytes.sublist(0, 7)), equals('NEPHRO1'));

      // Decrypt archive bytes back into PatientSyncBundle
      final decryptedBundle = await NephroArchiveCodec.decryptBundle(archiveBytes, passphrase: passphrase);

      expect(decryptedBundle.patient.id, equals(patient.id));
      expect(decryptedBundle.patient.name, equals('Grace Hopper'));
      expect(decryptedBundle.dialysisSessions.length, equals(1));
      expect(decryptedBundle.dialysisSessions.first.patientId, equals(patient.id));
    });

    test('Throws authentication error when decrypted with wrong passphrase', () async {
      final t0 = DateTime.utc(2026, 3, 1, 10, 0);
      final patient = await harness.createPatient(
        name: 'Grace Hopper',
        diagnosis: 'hemodialysis',
        createdAt: t0,
        updatedAt: t0,
      );

      final bundle = await PatientSyncBundle.fromDatabase(
        database: harness.database,
        patientId: patient.id,
      );

      final archiveBytes = await NephroArchiveCodec.encryptBundle(bundle, passphrase: 'CorrectPassword123');

      expect(
        () async => await NephroArchiveCodec.decryptBundle(archiveBytes, passphrase: 'WrongPassword456'),
        throwsA(isA<NephroArchiveDecryptionException>()),
      );
    });

    test('Throws exception when archive payload has invalid magic header or is tampered', () async {
      final tamperedBytes = Uint8List.fromList(List.filled(60, 0));
      expect(
        () async => await NephroArchiveCodec.decryptBundle(tamperedBytes, passphrase: 'Password123'),
        throwsA(isA<NephroArchiveDecryptionException>()),
      );
    });
  });
}
