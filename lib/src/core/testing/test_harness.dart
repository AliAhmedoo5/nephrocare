import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

/// Test harness establishing the Unified Application & State Seam.
///
/// Binds an in-memory Drift SQLite database to a Riverpod [ProviderContainer],
/// enabling end-to-end clinical workflow and state verification without emulator overhead.
class NephroTestHarness {
  final ProviderContainer container;
  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  NephroTestHarness({
    required this.container,
    required this.database,
  });

  /// Generates a RFC 4122 compliant UUIDv4 identifier.
  String generateUuid() => _uuid.v4();

  /// Tears down and disposes container and in-memory database connections.
  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

/// Factory function to construct an isolated [NephroTestHarness] with an in-memory database.
NephroTestHarness createNephroTestHarness() {
  final inMemoryDb = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(inMemoryDb),
    ],
  );

  return NephroTestHarness(
    container: container,
    database: inMemoryDb,
  );
}
