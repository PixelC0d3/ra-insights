/// Offline-first store. Every screen reads from here first.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Raw API payloads keyed by `<endpoint>:<args>`, with the fetch timestamp that
/// drives the TTLs from §5.4.
class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [CacheEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ra_insights'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  Future<CacheEntry?> readCache(String key) =>
      (select(cacheEntries)..where((t) => t.key.equals(key)))
          .getSingleOrNull();

  Stream<CacheEntry?> watchCache(String key) =>
      (select(cacheEntries)..where((t) => t.key.equals(key)))
          .watchSingleOrNull();

  Future<void> writeCache(String key, String payload) =>
      into(cacheEntries).insertOnConflictUpdate(CacheEntriesCompanion.insert(
        key: key,
        payload: payload,
        fetchedAt: DateTime.now(),
      ));

  Future<void> clearCache() => delete(cacheEntries).go();
}
