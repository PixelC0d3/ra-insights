/// dio client for the RetroAchievements Web API.
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../result.dart';
import 'request_queue.dart';

class RaCredentials {
  const RaCredentials({required this.username, required this.apiKey});
  final String username;
  final String apiKey;

  bool get isValid => username.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

const raApiBaseUrl = 'https://retroachievements.org/API/';

class RaClient {
  RaClient({Dio? dio, RequestQueue? queue, this.maxRetries = 3})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: raApiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
              responseType: ResponseType.json,
              headers: const {'User-Agent': 'RA-Insights/0.1 (unofficial)'},
            )),
        _queue = queue ?? RequestQueue();

  final Dio _dio;
  final RequestQueue _queue;
  final int maxRetries;

  RaCredentials? credentials;

  /// Every call goes through the queue; `429`/`5xx`/network errors back off
  /// exponentially before retrying.
  Future<Result<dynamic>> get(
    String endpoint, {
    Map<String, dynamic> params = const {},
    RaCredentials? overrideCredentials,
  }) async {
    final creds = overrideCredentials ?? credentials;
    if (creds == null || !creds.isValid) {
      return const Err(AppError(AppErrorKind.unauthorized, 'missing credentials'));
    }

    return _queue.add(() async {
      var attempt = 0;
      while (true) {
        try {
          final response = await _dio.get<dynamic>(
            '$endpoint.php',
            queryParameters: {
              // `z` is who authenticates and always stays ours; `u` is the
              // target user, which callers override to read another profile.
              // Sending only `u` would ask the API to authenticate *as them*
              // with our key.
              'z': creds.username,
              'u': creds.username,
              'y': creds.apiKey,
              ...params,
            },
          );
          final data = response.data;
          // A bad key answers 200 with an error envelope instead of a 401.
          if (data is Map && (data['Error'] != null || data['error'] != null)) {
            final msg = (data['Error'] ?? data['error']).toString();
            return Err<dynamic>(_envelopeError(msg));
          }
          return Ok<dynamic>(data);
        } on DioException catch (e) {
          final err = _mapDioError(e);
          attempt++;
          if (!err.isRetryable || attempt > maxRetries) return Err<dynamic>(err);
          await Future<void>.delayed(_backoff(attempt, e));
        } catch (e) {
          return Err<dynamic>(AppError(AppErrorKind.unknown, e.toString(), cause: e));
        }
      }
    });
  }

  Duration _backoff(int attempt, DioException e) {
    final retryAfter = e.response?.headers.value('retry-after');
    final seconds = int.tryParse(retryAfter ?? '');
    if (seconds != null) return Duration(seconds: seconds.clamp(1, 60));
    return Duration(milliseconds: 500 * (1 << (attempt - 1)));
  }

  AppError _envelopeError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('key') || lower.contains('credential') || lower.contains('auth')) {
      return AppError(AppErrorKind.unauthorized, msg);
    }
    if (lower.contains('not found') || lower.contains('unknown user')) {
      return AppError(AppErrorKind.notFound, msg);
    }
    return AppError(AppErrorKind.unknown, msg);
  }

  AppError _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return AppError(AppErrorKind.unauthorized, 'HTTP $status', cause: e);
    }
    if (status == 404) return AppError(AppErrorKind.notFound, 'HTTP 404', cause: e);
    if (status == 429) return AppError(AppErrorKind.rateLimited, 'HTTP 429', cause: e);
    if (status != null && status >= 500) {
      return AppError(AppErrorKind.network, 'HTTP $status', cause: e);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        AppError(AppErrorKind.network, e.message ?? 'network error', cause: e),
      DioExceptionType.badCertificate =>
        AppError(AppErrorKind.network, 'certificado inválido', cause: e),
      _ => AppError(AppErrorKind.unknown, e.message ?? 'erro desconhecido', cause: e),
    };
  }
}
