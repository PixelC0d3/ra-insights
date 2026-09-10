import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/almost_there.dart';

import 'helpers.dart';

void main() {
  test('empty input yields an empty list', () {
    expect(computeAlmostThere(const []), isEmpty);
  });

  test('keeps only games at 50% or more and not yet finished', () {
    final out = computeAlmostThere([
      game(id: 1, earned: 4, total: 10), // 40% — out
      game(id: 2, earned: 5, total: 10), // 50% — in
      game(id: 3, earned: 10, total: 10), // finished — out
      game(id: 4, earned: 9, total: 10), // 90% — in
    ]);
    expect(out.map((g) => g.gameId), [4, 2]);
  });

  test('games with no achievements at all do not divide by zero', () {
    final out = computeAlmostThere([game(id: 1, earned: 0, total: 0)]);
    expect(out, isEmpty);
  });

  test('sorted by proximity and capped at five', () {
    final out = computeAlmostThere([
      for (var i = 0; i < 8; i++) game(id: i, earned: 10 + i, total: 20),
    ]);
    expect(out.length, 5);
    expect(out.first.gameId, 7);
    expect(
      out.map((g) => g.progress).toList(),
      List.of(out.map((g) => g.progress))..sort((a, b) => b.compareTo(a)),
    );
  });

  test('remaining and percent are derived, not stored', () {
    final out = computeAlmostThere([game(earned: 7, total: 9)]);
    expect(out.single.remaining, 2);
    expect(out.single.percent, 78);
  });
}
