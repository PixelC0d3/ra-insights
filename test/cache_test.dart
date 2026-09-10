import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/core/db/database.dart';
import 'package:ra_insights/core/result.dart';
import 'package:ra_insights/data/cache.dart';

void main() {
  late AppDatabase db;
  late CacheStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = CacheStore(db);
  });

  tearDown(() => db.close());

  test('fresh cache short-circuits the network', () async {
    await store.write('k', {'v': 1});
    var fetched = false;

    final res = await cacheThenNetwork<int>(
      store: store,
      key: 'k',
      ttl: const Duration(minutes: 5),
      decode: (j) => (j as Map)['v'] as int,
      encode: (v) => {'v': v},
      fetch: () async {
        fetched = true;
        return const Ok(2);
      },
    );

    expect(fetched, isFalse);
    expect(res.valueOrNull!.value, 1);
    expect(res.valueOrNull!.stale, isFalse);
  });

  test('expired cache triggers a refresh and stores the new value', () async {
    await store.write('k', {'v': 1});

    final res = await cacheThenNetwork<int>(
      store: store,
      key: 'k',
      ttl: Duration.zero,
      decode: (j) => (j as Map)['v'] as int,
      encode: (v) => {'v': v},
      fetch: () async => const Ok(2),
    );

    expect(res.valueOrNull!.value, 2);
    final again = await store.read<int>(
        'k', const Duration(minutes: 5), (j) => (j as Map)['v'] as int);
    expect(again!.value, 2);
  });

  test('a failed refresh still serves stale data — that is offline-first', () async {
    await store.write('k', {'v': 1});

    final res = await cacheThenNetwork<int>(
      store: store,
      key: 'k',
      ttl: Duration.zero,
      decode: (j) => (j as Map)['v'] as int,
      encode: (v) => {'v': v},
      fetch: () async =>
          const Err(AppError(AppErrorKind.network, 'offline')),
    );

    expect(res.isOk, isTrue);
    expect(res.valueOrNull!.value, 1);
    expect(res.valueOrNull!.stale, isTrue);
  });

  test('a failure with no cache surfaces the error', () async {
    final res = await cacheThenNetwork<int>(
      store: store,
      key: 'missing',
      ttl: Duration.zero,
      decode: (j) => j as int,
      encode: (v) => v,
      fetch: () async =>
          const Err(AppError(AppErrorKind.network, 'offline')),
    );

    expect(res.isOk, isFalse);
    expect(res.errorOrNull!.kind, AppErrorKind.network);
  });

  test('an unparseable payload is treated as no cache at all', () async {
    await db.writeCache('k', 'not json');
    final read = await store.read<int>('k', const Duration(minutes: 5), (j) => j as int);
    expect(read, isNull);
  });
}
