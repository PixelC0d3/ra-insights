/// Serialized request queue with a minimum spacing between calls.
///
/// The API docs ask for moderation, so nothing here ever fans out in parallel
/// the way the userscript does — the yearly chunks queue up behind each other.
library;

import 'dart:async';
import 'dart:collection';

class RequestQueue {
  RequestQueue({this.minInterval = const Duration(milliseconds: 350)});

  final Duration minInterval;
  final Queue<_Job<dynamic>> _pending = Queue();
  bool _running = false;
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);

  int get pendingCount => _pending.length;

  Future<T> add<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _pending.add(_Job<T>(task, completer));
    unawaited(_drain());
    return completer.future;
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_pending.isNotEmpty) {
        final job = _pending.removeFirst();
        final since = DateTime.now().difference(_lastStart);
        final wait = minInterval - since;
        if (wait > Duration.zero) await Future<void>.delayed(wait);
        _lastStart = DateTime.now();
        try {
          final value = await job.task();
          if (!job.completer.isCompleted) job.completer.complete(value);
        } catch (e, st) {
          if (!job.completer.isCompleted) job.completer.completeError(e, st);
        }
      }
    } finally {
      _running = false;
    }
  }
}

class _Job<T> {
  _Job(this.task, this.completer);
  final Future<dynamic> Function() task;
  final Completer<dynamic> completer;
}
