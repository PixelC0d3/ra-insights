/// "What should I play now" — one pick, from what is already cached.
///
/// Score favours games close to mastery, with few achievements left, whose
/// remaining work is not brutally rare (average TrueRatio of the set).
library;

import 'almost_there.dart';

/// Carries the pick only; the reason line is built in the UI so it can be
/// localized.
class PlayNowPick {
  const PlayNowPick(this.game);
  final AlmostThereGame game;
}

PlayNowPick? pickWhatToPlay(List<AlmostThereGame> candidates) {
  if (candidates.isEmpty) return null;

  AlmostThereGame? best;
  var bestScore = double.negativeInfinity;
  for (final g in candidates) {
    // Proximity dominates; a short tail of remaining unlocks breaks ties.
    final score = g.progress * 100 - g.remaining * 2;
    if (score > bestScore) {
      bestScore = score;
      best = g;
    }
  }
  if (best == null) return null;
  return PlayNowPick(best);
}
