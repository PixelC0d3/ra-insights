/// `Result<T>` — no exception crosses a layer boundary.
library;

enum AppErrorKind { unauthorized, notFound, network, rateLimited, parse, unknown }

class AppError implements Exception {
  const AppError(this.kind, this.message, {this.cause});

  final AppErrorKind kind;
  final String message;
  final Object? cause;

  bool get isRetryable =>
      kind == AppErrorKind.network || kind == AppErrorKind.rateLimited;

  @override
  String toString() => 'AppError(${kind.name}: $message)';
}

sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.err(AppError error) = Err<T>;

  bool get isOk => this is Ok<T>;
  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;
  AppError? get errorOrNull => this is Err<T> ? (this as Err<T>).error : null;

  R fold<R>(R Function(T value) onOk, R Function(AppError error) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final error) => onErr(error),
      };

  Result<R> map<R>(R Function(T value) f) => switch (this) {
        Ok<T>(:final value) => Ok<R>(f(value)),
        Err<T>(:final error) => Err<R>(error),
      };

  /// Unwraps, rethrowing the error. Only for provider bodies, where Riverpod
  /// turns the throw back into `AsyncError`.
  T unwrap() => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>(:final error) => throw error,
      };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;
}
