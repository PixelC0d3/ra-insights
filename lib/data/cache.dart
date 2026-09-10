/// Cache-then-network plumbing shared by every repository.
library;

import 'dart:convert';

import '../core/db/database.dart';
import '../core/result.dart';

/// TTLs from §5.4 of the plan.
class CacheTtl {
  static const profile = Duration(minutes: 5);
  static const recent = Duration(minutes: 5);
  static const yearly = Duration(hours: 6);
  static const consoles = Duration(days: 30);
}

/// A value plus where it came from, so the UI can show "atualizado há X".
class Cached<T> {
  const Cached({required this.value, required this.fetchedAt, required this.stale});
  final T value;
  final DateTime? fetchedAt;
  final bool stale;
}

class CacheStore {
  CacheStore(this.db);
  final AppDatabase db;

  Future<Cached<T>?> read<T>(
    String key,
    Duration ttl,
    T Function(dynamic json) decode,
  ) async {
    final row = await db.readCache(key);
    if (row == null) return null;
    try {
      final decoded = decode(jsonDecode(row.payload));
      final stale = DateTime.now().difference(row.fetchedAt) > ttl;
      return Cached(value: decoded, fetchedAt: row.fetchedAt, stale: stale);
    } catch (_) {
      // A payload we can no longer parse is worse than no cache at all.
      return null;
    }
  }

  Future<void> write(String key, Object? json) =>
      db.writeCache(key, jsonEncode(json));
}

/// Reads cache, returns it when fresh, otherwise refreshes. A failed refresh
/// still yields stale data when there is any — that is the whole point of
/// offline-first.
Future<Result<Cached<T>>> cacheThenNetwork<T>({
  required CacheStore store,
  required String key,
  required Duration ttl,
  required T Function(dynamic json) decode,
  required Object? Function(T value) encode,
  required Future<Result<T>> Function() fetch,
  bool forceRefresh = false,
}) async {
  final cached = await store.read<T>(key, ttl, decode);
  if (cached != null && !cached.stale && !forceRefresh) return Ok(cached);

  final fresh = await fetch();
  switch (fresh) {
    case Ok(:final value):
      await store.write(key, encode(value));
      return Ok(Cached(value: value, fetchedAt: DateTime.now(), stale: false));
    case Err(:final error):
      if (cached != null) return Ok(cached);
      return Err(error);
  }
}
