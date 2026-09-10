import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/core/api/request_queue.dart';

void main() {
  test('requests run one at a time, never fanned out in parallel', () async {
    final queue = RequestQueue(minInterval: Duration.zero);
    var inFlight = 0;
    var maxInFlight = 0;

    await Future.wait([
      for (var i = 0; i < 8; i++)
        queue.add(() async {
          inFlight++;
          if (inFlight > maxInFlight) maxInFlight = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
          return i;
        }),
    ]);

    expect(maxInFlight, 1);
  });

  test('a minimum interval is kept between calls', () async {
    final queue = RequestQueue(minInterval: const Duration(milliseconds: 40));
    final started = <DateTime>[];
    await Future.wait([
      for (var i = 0; i < 3; i++)
        queue.add(() async {
          started.add(DateTime.now());
          return i;
        }),
    ]);
    expect(started[1].difference(started[0]).inMilliseconds,
        greaterThanOrEqualTo(35));
    expect(started[2].difference(started[1]).inMilliseconds,
        greaterThanOrEqualTo(35));
  });

  test('a failing job does not stall the queue', () async {
    final queue = RequestQueue(minInterval: Duration.zero);
    final failed = queue.add<int>(() async => throw StateError('boom'));
    final ok = queue.add<int>(() async => 7);

    await expectLater(failed, throwsStateError);
    expect(await ok, 7);
  });

  test('results keep their static type', () async {
    final queue = RequestQueue(minInterval: Duration.zero);
    final value = await queue.add<String>(() async => 'hello');
    expect(value, 'hello');
  });
}
