import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/core/api/ra_api.dart';
import 'package:ra_insights/core/api/ra_client.dart';
import 'package:ra_insights/core/api/request_queue.dart';
import 'package:ra_insights/core/result.dart';

/// Answers from a canned map instead of the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? stream,
      Future<void>? cancelFuture) async {
    calls.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

// ignore: library_private_types_in_public_api
RaClient clientWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: raApiBaseUrl))
    ..httpClientAdapter = adapter;
  return RaClient(dio: dio, queue: RequestQueue(minInterval: Duration.zero))
    ..credentials = const RaCredentials(username: 'me', apiKey: 'k');
}

void main() {
  test('credentials go on the query string of every call', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString(
        '{"User":"me","TotalPoints":10}', 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        }));
    final api = RaApi(clientWith(adapter));

    final res = await api.getUserProfile();
    expect(res.isOk, isTrue);
    expect(adapter.calls.single.queryParameters['z'], 'me');
    expect(adapter.calls.single.queryParameters['u'], 'me');
    expect(adapter.calls.single.queryParameters['y'], 'k');
    expect(adapter.calls.single.path, 'API_GetUserProfile.php');
  });

  test('reading another profile keeps us as the authenticated user', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString(
        '{"User":"televandalist","TotalPoints":10}', 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        }));
    final api = RaApi(clientWith(adapter));

    await api.getProfileOf('televandalist');
    final query = adapter.calls.single.queryParameters;
    // `u` is the target, `z` stays ours — swapping them would ask the API to
    // authenticate as the other player with our key.
    expect(query['u'], 'televandalist');
    expect(query['z'], 'me');
    expect(query['y'], 'k');
  });

  test('the events catalogue is read as a console game list', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString(
        '[{"ID":191,"Title":"Challenge League 7 Wonders","ConsoleID":101,'
        '"ConsoleName":"Events","NumAchievements":42,"Points":420}]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        }));
    final api = RaApi(clientWith(adapter));

    final res = await api.getGameList(101);
    expect(res.isOk, isTrue);
    expect(res.valueOrNull!.single.numAchievements, 42);

    final query = adapter.calls.single.queryParameters;
    expect(query['i'], 101);
    // Events with no achievements are noise for the challenges screen.
    expect(query['f'], 1);
    expect(query['z'], 'me');
    expect(query['y'], 'k');
  });

  test('the system list keeps Hubs and Events in by default', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString(
        '[{"ID":101,"Name":"Events"}]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    }));
    final api = RaApi(clientWith(adapter));

    final res = await api.getConsoleIds();
    expect(res.valueOrNull!.single.name, 'Events');
    // g=1 would filter Events out, which is the one system we need.
    expect(adapter.calls.single.queryParameters['g'], 0);
  });

  test('an error envelope returned with HTTP 200 becomes a typed error', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString(
        '{"Error":"Invalid API Key"}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    }));
    final res = await RaApi(clientWith(adapter)).getUserProfile();
    expect(res.errorOrNull!.kind, AppErrorKind.unauthorized);
  });

  test('HTTP 401 maps to unauthorized and is not retried', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString('{}', 401));
    final res = await RaApi(clientWith(adapter)).getUserSummary();
    expect(res.errorOrNull!.kind, AppErrorKind.unauthorized);
    expect(adapter.calls.length, 1);
  });

  test('HTTP 429 is retried with backoff before giving up', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString('{}', 429));
    final client = clientWith(adapter);
    final res = await RaApi(client).getUserSummary();
    expect(res.errorOrNull!.kind, AppErrorKind.rateLimited);
    expect(adapter.calls.length, client.maxRetries + 1);
  });

  test('missing credentials fail fast without touching the network', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString('{}', 200));
    final client = clientWith(adapter)..credentials = null;
    final res = await RaApi(client).getUserSummary();
    expect(res.errorOrNull!.kind, AppErrorKind.unauthorized);
    expect(adapter.calls, isEmpty);
  });

  test('awards are unwrapped from VisibleUserAwards', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString(
        '{"VisibleUserAwards":[{"AwardType":"Mastery/Completion","AwardDataExtra":1,'
        '"AwardData":"42","AwardedAt":"2026-08-01T10:00:00+00:00"}]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        }));
    final res = await RaApi(clientWith(adapter)).getUserAwards();
    expect(res.valueOrNull!.single.gameId, 42);
  });

  test('a list endpoint answering {} is read as an empty list', () async {
    final adapter = _FakeAdapter((_) => ResponseBody.fromString('{}', 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        }));
    final res = await RaApi(clientWith(adapter)).getRecentAchievements();
    expect(res.valueOrNull, isEmpty);
  });
}
